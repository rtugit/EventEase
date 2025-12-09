class Event < ApplicationRecord
  belongs_to :organizer, class_name: "User"
  has_many :registrations, dependent: :destroy, inverse_of: :event

  validates :title, presence: true
  validates :description, presence: true
  validates :location, presence: true
  validates :starts_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published archived] }
  validate :ends_at_after_starts_at

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?

    return unless ends_at < starts_at

    errors.add(:ends_at, "must be after the start date")
  end
end
