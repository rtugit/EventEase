class RegistrationsController < ApplicationController
  # Require authentication for all actions
  before_action :authenticate_user!

  # Used when creating a new registration for a specific event
  before_action :set_event, only: [:create]

  # Used when cancelling or checking in a specific registration
  before_action :set_registration, only: %i[destroy check_in]
  before_action :authorize_registration, only: [:destroy]

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
    @event = @registration.event
    @registration.destroy
    redirect_to event_path(@event), notice: "You have successfully unjoined the event."
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

  def authorize_registration
    # User can only unjoin their own registration
    unless @registration.email == current_user.email
      redirect_to event_path(@registration.event), alert: "You can only unjoin your own registration."
    end
  end
end
