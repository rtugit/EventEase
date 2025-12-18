class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :set_comment, only: %i[update destroy]
  before_action :authorize_comment, only: %i[update destroy]

  def create
    @comment = @event.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to event_path(@event, anchor: "comments-panel"), notice: "Comment posted successfully!"
    else
      redirect_to event_path(@event, anchor: "comments-panel"), alert: @comment.errors.full_messages.join(", ")
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to event_path(@event, anchor: "comments-panel"), notice: "Comment updated successfully!"
    else
      redirect_to event_path(@event, anchor: "comments-panel"), alert: @comment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @comment.destroy
    redirect_to event_path(@event, anchor: "comments-panel"), notice: "Comment deleted successfully!"
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_comment
    @comment = @event.comments.find(params[:id])
  end

  def authorize_comment
    return if @comment.user == current_user

    redirect_to event_path(@event, anchor: "comments-panel"), alert: "You can only edit or delete your own comments."
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end

