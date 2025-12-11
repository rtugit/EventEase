class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: %i[show edit update destroy]

  def index
    @popular_events = Event.popular
    @new_events     = Event.upcoming

    @events = Event.all
    @events = current_user.events.includes(:registrations).order(starts_at: :asc)

    if params[:query].present?
      @events = @events.where("title ILIKE ?", "%#{params[:query]}%")
    end

    if params[:location].present?
      @events = @events.where("location ILIKE ?", "%#{params[:location]}%")
    end

    if params[:date].present?
      @events = @events.where(date: params[:date])
    end

  end

  def show
    # @event is set by before_action
  end

  def new
    @event = Event.new
  end

  def edit
  end

  def create
    @event = current_user.organized_events.build(event_params)
    if @event.save
      redirect_to event_path(@event), notice: t('.success')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @event.update(event_params)
      redirect_to event_path(@event), notice: t('.success')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, status: :see_other, notice: t('.success')
  end


  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :location, :description, :starts_at, :ends_at, :capacity, photos: [])
  end
end
