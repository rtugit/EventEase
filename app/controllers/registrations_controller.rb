class RegistrationsController < ApplicationController
  # We need to make sure a user is logged in before they can check someone in.
  before_action :authenticate_user!, only: [:check_in]

  # Find the event before creating a registration, so we know which event it belongs to.
  before_action :set_event, only: [:create]

  # Find the specific registration for actions that need to modify or delete it.
  before_action :set_registration, only: %i[destroy check_in]

  # POST /events/:event_id/registrations
  def create
    # Build a new registration for the specific event using the form data (params)
    @registration = @event.registrations.build(registration_params)

    if @registration.save
      # If successful, redirect to the event page with a success message
      redirect_to event_path(@event), notice: "You have successfully joined the event!"
    else
      # If saving fails (e.g. missing email), go back to the event page and show the error
      redirect_to event_path(@event), alert: "RSVP failed: #{@registration.errors.full_messages.join(', ')}"
    end
  end

  # DELETE /registrations/:id
  def destroy
    # Delete the registration from the database
    @registration.destroy

    # Redirect the user back to the event page
    redirect_to event_path(@registration.event), notice: "RSVP cancelled."
  end

  # PATCH /registrations/:id/check_in
  def check_in
    # First, ensure the current user is actually the organizer of this event
    if @registration.event.organizer == current_user
      # If authorized, mark the registration as checked in
      @registration.check_in!
      redirect_to dashboard_path, notice: "Attendee checked in."
    else
      # If not authorized, show an error
      redirect_to dashboard_path, alert: "Not authorized to check in."
    end
  end

  private

  # These methods are only used internally by this controller

  def set_event
    # Find the event using the 'event_id' from the URL
    @event = Event.find(params[:event_id])
  end

  def set_registration
    # Find the registration using the 'id' from the URL
    @registration = Registration.find(params[:id])
  end

  # Strong Parameters: only allow specific fields to be submitted for security
  def registration_params
    params.require(:registration).permit(:email, :name)
  end
end
