class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: %i[show edit update destroy check_in]

  def index
    # Check if filtering by "My Events"
    if params[:filter] == 'my_events'
      # Events where user is organizer OR user has a registration (by user_id or email)
      my_event_ids = current_user.events.pluck(:id)
      registered_event_ids = Registration.where(user_id: current_user.id)
                                         .or(Registration.where(email: current_user.email))
                                         .pluck(:event_id)
      all_my_event_ids = (my_event_ids + registered_event_ids).uniq
      
      @events = Event.where(id: all_my_event_ids).includes(:registrations, :organizer).order(starts_at: :asc)
    else
      # Fetch current user's events (organizer's own events)
      @events = current_user.events.includes(:registrations).order(starts_at: :asc)
    end

    # Fetch popular and upcoming events for discovery (only if not filtering my events)
    unless params[:filter] == 'my_events'
      @popular_events = Event.where(status: 'published').popular.includes(:registrations)
      @new_events = Event.where(status: 'published').upcoming.includes(:registrations)
    end

    # Search by title
    @events = @events.where("title ILIKE ?", "%#{params[:title]}%") if params[:title].present?

    # Filter by location
    @events = @events.where("location ILIKE ?", "%#{params[:location]}%") if params[:location].present?

    # Filter by date
    return if params[:date].blank?

    @events = @events.where("DATE(starts_at) = ?", params[:date])
  end

  def show
    # @event is set by before_action
    @reviews = @event.reviews.recent.includes(:registration)
    # Find user's registration if they're signed in
    @user_registration = @event.registrations.find_by(email: current_user.email) if user_signed_in?
  end

  def new
    @event = Event.new
    @event.rundown_items.build
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
      redirect_to event_path(@event), notice: t('.success')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    combine_date_time(@event)
    assign_rundown_positions(@event)
    if @event.update(event_params)
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
      photos: [],
      rundown_items_attributes: %i[id heading description position _destroy]
    )
  end

  def combine_date_time(event)
    return unless event.event_date.present? && event.event_time.present?

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
      # If parsing fails, leave starts_at as is (will be validated by model)
      Rails.logger.error("Failed to parse date/time: #{e.message}")
    end
  end

  def assign_rundown_positions(event)
    return if event.rundown_items.blank?

    event.rundown_items.reject(&:marked_for_destruction?).each_with_index do |item, index|
      item.position = index + 1
    end
  end

  def authorize_organizer
    return if @event.organizer == current_user

    redirect_to event_path(@event), alert: "You are not authorized to perform this action." and return
  end
end
