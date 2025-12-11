class Event < ApplicationRecord
  belongs_to :organizer, class_name: "User"
  has_many :registrations, dependent: :destroy, inverse_of: :event

  validates :title, presence: true
  validates :description, presence: true
  validates :location, presence: true
  validates :starts_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published archived] }
  validate :ends_at_after_starts_at

  scope :search_title, ->(q) { where("title ILIKE ?", "%#{q}%") if q.present? }
  scope :search_location, ->(l) { where("location ILIKE ?", "%#{l}%") if l.present? }
  scope :search_date, ->(d) { where(date: d) if d.present? }

  # For now, we will treat newest events as "popular"
  scope :popular, -> { order(created_at: :desc).limit(10) }

  # New events = upcoming soonest
  scope :upcoming, -> { order(starts_at: :asc).limit(10) }

  has_many_attached :photos

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?

    return unless ends_at < starts_at

    errors.add(:ends_at, "must be after the start date")
  end
end
