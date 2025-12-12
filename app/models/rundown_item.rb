class RundownItem < ApplicationRecord
  belongs_to :event

  validates :heading, presence: true, if: -> { !marked_for_destruction? }
  validates :description, presence: true, if: -> { !marked_for_destruction? }
  validates :position, numericality: { only_integer: true }, allow_nil: true

  scope :ordered, -> { order(:position) }
end
