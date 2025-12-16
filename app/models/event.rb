class Event < ApplicationRecord
  belongs_to :organizer, class_name: "User"
  has_many :registrations, dependent: :destroy, inverse_of: :event, counter_cache: true
  has_many :active_registrations, -> { where.not(status: 'cancelled') }, class_name: 'Registration', inverse_of: :event # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :rundown_items, dependent: :destroy
  has_many :reviews, dependent: :destroy

  def past?
    starts_at.present? && starts_at < Time.current
  end

  # Virtual attributes for date/time form fields
  attr_accessor :event_date, :event_time

  CATEGORIES = [
    "Networking",
    "Sport & Activity",
    "Party & Social",
    "Talk",
    "Community",
    "Study",
    "Other"
  ].freeze

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :location, presence: true, length: { maximum: 255 }
  validates :starts_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published archived] }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validate :ends_at_after_starts_at

  # Set virtual attributes from starts_at when loading the model
  after_initialize :set_date_time_from_starts_at
  # Sanitize HTML content to prevent XSS attacks
  before_save :sanitize_inputs

  # Enable nested attributes for rundown items
  accepts_nested_attributes_for :rundown_items, allow_destroy: true, reject_if: :all_blank

  scope :search_title, ->(q) { where("title ILIKE ?", "%#{q}%") if q.present? }
  scope :search_location, ->(l) { where("location ILIKE ?", "%#{l}%") if l.present? }
  scope :search_date, ->(d) { where(date: d) if d.present? }

  # For now, we will treat newest events as "popular"
  scope :popular, -> { order(created_at: :desc).limit(10) }

  # New events = upcoming soonest
  scope :upcoming, -> { order(starts_at: :asc).limit(10) }

  has_many_attached :photos

  # Callback to handle capacity reduction
  after_update :enforce_capacity_limit

  # Count active registrations (not cancelled)
  delegate :count, to: :active_registrations, prefix: true

  # Check if event has available spots
  def available_spots?
    return true if capacity.nil? # Unlimited capacity

    active_registrations_count < capacity
  end

  # Get number of available spots
  def available_spots
    return nil if capacity.nil? # Unlimited

    [capacity - active_registrations_count, 0].max
  end

  private

  def set_date_time_from_starts_at
    return if starts_at.blank?

    self.event_date ||= starts_at.strftime("%Y-%m-%d")
    self.event_time ||= starts_at.strftime("%H:%M")
  end

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?

    return unless ends_at < starts_at

    errors.add(:ends_at, "must be after the start date")
  end

  def sanitize_inputs
    self.title = ActionController::Base.helpers.sanitize(title, tags: [], attributes: []) if title.present?
    self.location = ActionController::Base.helpers.sanitize(location, tags: [], attributes: []) if location.present?
    # Description can include basic formatting
    return if description.blank?

    self.description = ActionController::Base.helpers.sanitize(description, tags: %w[p br ul ol li strong em],
                                                                            attributes: [])
  end

  def enforce_capacity_limit
    # Only enforce if capacity was changed and is not nil
    return unless saved_change_to_capacity?
    return if capacity.nil? # Unlimited capacity

    current_count = active_registrations_count
    return if current_count <= capacity # No need to remove anyone

    # Remove the most recently registered guests (last arrived)
    excess_count = current_count - capacity
    registrations
      .where.not(status: 'cancelled')
      .order(created_at: :desc) # Most recent first
      .limit(excess_count)
      .each(&:destroy)
  end
end
