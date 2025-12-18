class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: %i[show edit update destroy check_in]

  def index
    # Check if filtering by "My Events"
    if params[:filter] == 'my_events'
      my_event_ids = current_user.events.pluck(:id)
      registered_event_ids = Registration.where(user_id: current_user.id)
                                        .or(Registration.where(email: current_user.email))
                                        .pluck(:event_id)
      all_my_event_ids = (my_event_ids + registered_event_ids).uniq

      # My Upcoming Events
      @my_upcoming_events = Event.where(id: all_my_event_ids)
                                .where('starts_at >= ? AND starts_at <= ?', Time.current, 1.week.from_now)
                                .order(starts_at: :asc)
                                .includes(:registrations, :organizer)

      # My Events - apply sorting
      @events = Event.where(id: all_my_event_ids)
                    .includes(:registrations, :organizer)

      # Apply sorting for My Events
      @events = case params[:sort]
      when 'title_asc'
        @events.order('LOWER(title) ASC')
      when 'title_desc'
        @events.order('LOWER(title) DESC')
      when 'date_desc'
        @events.order(starts_at: :desc)
      when 'location_asc'
        @events.order('LOWER(location) ASC')
      when 'location_desc'
        @events.order('LOWER(location) DESC')
      else
        # Default: date ascending (earliest first)
        @events.order(starts_at: :asc)
      end
    else
      @events = current_user.events.includes(:registrations).order(starts_at: :asc)
    end

    # Fetch popular and upcoming events for discovery
    unless params[:filter] == 'my_events'
      my_private_event_ids = current_user.events.private_events.pluck(:id)
      registered_private_event_ids = Registration.where(user_id: current_user.id)
                                                 .or(Registration.where(email: current_user.email))
                                                 .joins(:event)
                                                 .where(events: { private: true })
                                                 .pluck(:event_id)
      visible_private_event_ids = (my_private_event_ids + registered_private_event_ids).uniq

      if visible_private_event_ids.any?
        visibility_condition = Event.where(private: false).or(Event.where(id: visible_private_event_ids))
      else
        visibility_condition = Event.where(private: false)
      end

      # Upcoming events
      @upcoming_events = visibility_condition
                         .where(status: 'published')
                         .where('starts_at >= ? AND starts_at <= ?', Time.current, 1.week.from_now)
                         .order(starts_at: :asc)
                         .includes(:registrations)
                         .limit(10)

      # All events (including user's own events)
      all_events_base = Event.where(status: 'published')
                            .where('private = ? OR organizer_id = ?', false, current_user.id)
                            .or(Event.where(id: visible_private_event_ids))
                            .left_outer_joins(:registrations)
                            .group('events.id')
                            .select('events.*, COUNT(registrations.id) AS registrations_count')
                            .includes(:registrations)

      @popular_events = all_events_base
      # Show public events + private events user has access to (kann Duplikate mit Upcoming haben)
      @popular_events = visibility_condition
                        .where(status: 'published')
                        .left_outer_joins(:registrations)
                        .group('events.id')
                        .select('events.*, COUNT(registrations.id) AS registrations_count')
                        .order('COUNT(registrations.id) DESC')
                        .includes(:registrations)
                        .limit(10)
    end

    # Filter by title
    if params[:title].present?
      search_term = params[:title].strip
      sanitized_term = ActiveRecord::Base.connection.quote_string(search_term)

      @events = @events
                .where("title ILIKE ?", "%#{search_term}%")
                .reorder(Arel.sql("
          CASE
            WHEN LOWER(title) = LOWER('#{sanitized_term}') THEN 1
            WHEN LOWER(title) LIKE LOWER('#{sanitized_term}%') THEN 2
            WHEN LOWER(title) LIKE LOWER('% #{sanitized_term}%') THEN 3
            ELSE 4
          END, title ASC
        "))

      @popular_events = @popular_events&.where("events.title ILIKE ?", "%#{search_term}%")
      @upcoming_events = @upcoming_events&.where("events.title ILIKE ?", "%#{search_term}%")
    end

    # Filter by location
    if params[:location].present?
      @events = @events.where("location ILIKE ?", "%#{params[:location]}%")
      @popular_events = @popular_events&.where("events.location ILIKE ?", "%#{params[:location]}%")
      @upcoming_events = @upcoming_events&.where("events.location ILIKE ?", "%#{params[:location]}%")
    end

    # Filter by date
    if params[:date].present?
      search_date = begin
        Date.parse(params[:date])
      rescue StandardError
        nil
      end
      if search_date
        @events = @events.where("DATE(starts_at) = ?", search_date)
        @popular_events = @popular_events&.where("DATE(events.starts_at) = ?", search_date)
        @upcoming_events = @upcoming_events&.where("DATE(events.starts_at) = ?", search_date)
      end
    end

    # Filter by category
    if params[:category].present?
      @events = @events.where(category: params[:category])
      @popular_events = @popular_events&.where(events: { category: params[:category] })
      @upcoming_events = @upcoming_events&.where(events: { category: params[:category] })
    end

    # Apply sorting for All Events (only when not filtering My Events)
    unless params[:filter] == 'my_events'
      if @popular_events
        @popular_events = case params[:sort]
        when 'title_asc'
          @popular_events.reorder('LOWER(events.title) ASC')
        when 'title_desc'
          @popular_events.reorder('LOWER(events.title) DESC')
        when 'date_asc'
          @popular_events.reorder('events.starts_at ASC')
        when 'date_desc'
          @popular_events.reorder('events.starts_at DESC')
        when 'location_asc'
          @popular_events.reorder('LOWER(events.location) ASC')
        when 'location_desc'
          @popular_events.reorder('LOWER(events.location) DESC')
        else
          # Default: most popular
          @popular_events.reorder('COUNT(registrations.id) DESC')
        end

        @popular_events = @popular_events.limit(20)
      end
    end
  end

  # Autocomplete suggestions endpoint (only search public events)
  def search_suggestions
    query = params[:q].to_s.strip
    type = params[:type].to_s

    suggestions = []

    if query.length >= 2
      case type
      when 'title'
        # Get matching event titles (only public events)
        titles = Event.public_events
                      .where("title ILIKE ?", "%#{query}%")
                      .distinct
                      .limit(8)
                      .pluck(:title)

        suggestions = titles.map do |title|
          {
            value: title,
            label: title,
            icon: 'fa-calendar-days'
          }
        end

      when 'location'
        # Get matching locations (only public events)
        locations = Event.public_events
                         .where("location ILIKE ?", "%#{query}%")
                         .select(:location)
                         .distinct
                         .limit(8)
                         .pluck(:location)

        suggestions = locations.compact.map do |location|
          {
            value: location,
            label: location,
            icon: 'fa-location-dot'
          }
        end
      end
    end

    render json: suggestions
  end

  def show
    # @event is set by before_action
    @reviews = @event.reviews.recent.includes(:registration)
    # Find user's registration if they're signed in
    @user_registration = @event.registrations.find_by(email: current_user.email) if user_signed_in?
  end

  def new
    @event = Event.new
  end

  def edit
    # @event is set by before_action
    authorize_organizer
  end

  def create
    @event = current_user.events.build(event_params)
    combine_date_time(@event)
    assign_rundown_positions(@event)

    if @event.save
      # Attach AI image AFTER successful save (so it doesn't get overwritten)
      attach_ai_image(@event)
      redirect_to event_path(@event), notice: t('.success')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    assign_rundown_positions(@event)

    # Remove empty photos from params to prevent overwriting existing/AI images
    params[:event].delete(:photos) if params[:event][:photos].blank? || params[:event][:photos].all?(&:blank?)

    # Assign new attributes first so we can recalculate starts_at from them
    @event.assign_attributes(event_params)
    combine_date_time(@event)

    if @event.save
      # Attach AI image AFTER successful update (so it doesn't get overwritten)
      attach_ai_image(@event)
      redirect_to event_path(@event), notice: t('.success')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize_organizer
    @event.destroy
    redirect_to events_path, status: :see_other, notice: t('.success')
  end

  def check_in
    # Only the organizer should access the check-in mode for this event
    unless @event.organizer == current_user
      redirect_to event_path(@event),
                  alert: "You are not allowed to access the check-in mode for this event." and return
    end

    @registrations = @event.registrations.order(created_at: :asc)
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :title,
      :location,
      :description,
      :starts_at,
      :ends_at,
      :capacity,
      :category,
      :event_date,
      :event_time,
      :event_end_date,
      :event_end_time,
      :private,
      photos: [],
      rundown_items_attributes: %i[id heading description position _destroy]
    )
  end

  def combine_date_time(event)
    # 1. Update starts_at
    if event.event_date.present? && event.event_time.present?
      begin
        date = Date.parse(event.event_date)
        time = Time.zone.parse(event.event_time)
        event.starts_at = Time.zone.local(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.min
        )
      rescue ArgumentError => e
        Rails.logger.error("Failed to parse start date/time: #{e.message}")
      end
    end

    # 2. Update ends_at
    return unless event.event_end_date.present? && event.event_end_time.present?

    begin
      end_date = Date.parse(event.event_end_date)
      end_time = Time.zone.parse(event.event_end_time)
      event.ends_at = Time.zone.local(
        end_date.year,
        end_date.month,
        end_date.day,
        end_time.hour,
        end_time.min
      )
    rescue ArgumentError => e
      Rails.logger.error("Failed to parse end date/time: #{e.message}")
    end
  end

  def assign_rundown_positions(event)
    return if event.rundown_items.blank?

    event.rundown_items.reject(&:marked_for_destruction?).each_with_index do |item, index|
      item.position = index + 1
    end
  end

  def attach_ai_image(event)
    ai_image_url = params.dig(:event, :ai_image_url)
    return if ai_image_url.blank?

    begin
      require 'open-uri'

      # Download the image from OpenAI's temporary URL
      downloaded_image = URI.open(ai_image_url)

      # Generate a unique filename
      filename = "ai_generated_#{Time.current.to_i}.png"

      # Attach the image to the event
      event.photos.attach(
        io: downloaded_image,
        filename: filename,
        content_type: 'image/png'
      )

      Rails.logger.info "AI Image attached successfully: #{filename}"
    rescue StandardError => e
      Rails.logger.error "Failed to attach AI image: #{e.message}"
    end
  end

  def authorize_organizer
    return if @event.organizer == current_user

    redirect_to event_path(@event), alert: "You are not authorized to perform this action." and return
  end
end
