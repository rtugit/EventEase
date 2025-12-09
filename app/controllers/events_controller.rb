class EventsController < ApplicationController
  before_action :authenticate_user!

  def organizer
    @events = current_user.events.includes(:registrations).order(starts_at: :asc)
  end
end
