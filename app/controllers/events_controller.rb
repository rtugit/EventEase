class EventsController < ApplicationController
  before_action :authenticate_user!

  def index
    @events = current_user.events.includes(:registrations).order(starts_at: :asc)
  end
end
