class Review < ApplicationRecord
  belongs_to :event
  belongs_to :registration

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 1000 }
  validates :registration_id, uniqueness: { scope: :event_id, message: :taken }

  scope :recent, -> { order(created_at: :desc) }
end
