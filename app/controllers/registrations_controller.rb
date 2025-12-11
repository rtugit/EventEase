class RegistrationsController < ApplicationController
  # Only organizers need to be logged in for check-in
  before_action :authenticate_user!, only: [:check_in]

  # Used when creating a new registration for a specific event
  before_action :set_event, only: [:create]

  # Used when cancelling or checking in a specific registration
  before_action :set_registration, only: %i[destroy check_in]

  # POST /events/:event_id/registrations
  def create
    @registration = @event.registrations.build(registration_params)

    if @registration.save
      redirect_to event_path(@event), notice: t('.success')
    else
      redirect_to event_path(@event),
                  alert: t('.failure', errors: @registration.errors.full_messages.join(', '))
    end
  end

  # DELETE /registrations/:id
  def destroy
    # Use model logic to cancel instead of hard delete
    @registration.cancel!
    redirect_to event_path(@registration.event), notice: t('.cancelled')
  end

  # PATCH /registrations/:id/check_in
  def check_in
    # Only the organizer of the event is allowed to check people in
    unless @registration.event.organizer == current_user
      redirect_to dashboard_path, alert: t('.unauthorized') and return
    end

    # Toggle between "checked_in" and "registered"
    if @registration.status == "checked_in"
      @registration.update!(status: "registered", check_in_at: nil)
    else
      @registration.check_in!
    end

    # Stay on the event's check-in mode page
    redirect_to check_in_event_path(@registration.event), notice: t('.success')
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_registration
    @registration = Registration.find(params[:id])
  end

  def registration_params
    params.require(:registration).permit(:email, :name)
  end
end
