class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :first_name, presence: true
  validates :last_name, presence: true

  has_many :events, class_name: "Event", foreign_key: "organizer_id", inverse_of: :organizer,
                    dependent: :destroy
  has_one_attached :photo

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end
end
