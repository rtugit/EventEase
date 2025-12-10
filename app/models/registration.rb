class Registration < ApplicationRecord
  belongs_to :event, inverse_of: :registrations

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: %w[registered checked_in cancelled] }
  validates :email, uniqueness: { scope: :event_id }

  def check_in!
    update!(status: "checked_in", check_in_at: Time.current)
  end

  def cancel!
    update!(status: "cancelled", cancelled_at: Time.current)
  end
end
