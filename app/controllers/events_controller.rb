class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: %i[show edit update destroy]

  def index
    @events = current_user.events.includes(:registrations).order(starts_at: :asc)

    return if params[:query].blank?

    @events = @events.where("title ILIKE :query OR location ILIKE :query", query: "%#{params[:query]}%")
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
      redirect_to event_path(@event), notice: "Event created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @event.update(event_params)
      redirect_to event_path(@event), notice: "Event updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, status: :see_other, notice: "Event deleted."
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :location, :description, :starts_at, :ends_at, :capacity)
  end
end
