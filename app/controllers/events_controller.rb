class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: [:show, :edit, :update, :destroy] //is it the same as above?

  def index
    @events = current_user.events.includes(:registrations).order(starts_at: :asc)
  end

  def show
    @event = Event.find(param[:id]) #(Maybe no need)
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    @event.save
    redirect_ to event_path(@event)
  end

  def edit
  end

  def update
    @event.update(event_params)
    redirect_to event_path(@event)
  end

  def destroy
    @event.destroy
    redirect_to events_path, status: :see_other
  end

  private
  def set_event
    @event = Event.find(param[:id]) #For show, edit, update
  end
  def event_params
    params.require(:event).permit(:name, :address, :rating) #For update, create(new)
  end
end
