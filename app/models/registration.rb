class Registration < ApplicationRecord
  belongs_to :event, inverse_of: :registrations
  has_many :reviews, dependent: :destroy

  def reviewed?
    reviews.present?
  end

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: %w[registered checked_in cancelled] }
  validates :email, uniqueness: { scope: :event_id }
  validate :event_has_capacity, on: :create

  def check_in!
    update!(status: "checked_in", check_in_at: Time.current)
  end

  def cancel!
    update!(status: "cancelled", cancelled_at: Time.current)
  end

  private

  def event_has_capacity
    return if event.nil?
    return if event.capacity.nil? # Unlimited capacity

    return unless event.active_registrations_count >= event.capacity

    errors.add(:base, "This event is at full capacity. No more registrations can be accepted.")
  end
end
