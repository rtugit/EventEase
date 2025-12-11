class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :set_registration, only: [:create]
  before_action :set_review, only: [:update, :destroy]
  before_action :authorize_review, only: [:update, :destroy]

  def create
    @review = @event.reviews.build(review_params)
    @review.registration = @registration

    if @review.save
      redirect_to event_path(@event, anchor: "reviews-panel"), notice: "Review submitted successfully!"
    else
      redirect_to event_path(@event, anchor: "reviews-panel"), alert: @review.errors.full_messages.join(", ")
    end
  end

  def update
    if @review.update(review_params)
      redirect_to event_path(@event, anchor: "reviews-panel"), notice: "Review updated successfully!"
    else
      redirect_to event_path(@event, anchor: "reviews-panel"), alert: @review.errors.full_messages.join(", ")
    end
  end

  def destroy
    @review.destroy
    redirect_to event_path(@event, anchor: "reviews-panel"), notice: "Review deleted successfully!"
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_registration
    @registration = @event.registrations.find_by(email: current_user.email)
    
    unless @registration
      redirect_to event_path(@event), alert: "You must join the event before reviewing it."
      return
    end

    if @registration.reviewed?
      redirect_to event_path(@event, anchor: "reviews-panel"), alert: "You have already reviewed this event."
      return
    end
  end

  def set_review
    @review = @event.reviews.find(params[:id])
  end

  def authorize_review
    unless @review.registration.email == current_user.email
      redirect_to event_path(@event, anchor: "reviews-panel"), alert: "You can only edit or delete your own review."
    end
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end

