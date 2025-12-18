class Comment < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :content, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }
end

