class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :first_name, presence: true, length: { maximum: 255 }
  validates :last_name, presence: true, length: { maximum: 255 }
  validates :phone_number, length: { maximum: 255 }, allow_blank: true

  has_many :events, class_name: "Event", foreign_key: "organizer_id", inverse_of: :organizer,
                    dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one_attached :photo

  # Sanitize inputs to prevent XSS
  before_save :sanitize_inputs

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def sanitize_inputs
    if first_name.present?
      self.first_name = ActionController::Base.helpers.sanitize(first_name, tags: [],
                                                                            attributes: [])
    end
    self.last_name = ActionController::Base.helpers.sanitize(last_name, tags: [], attributes: []) if last_name.present?
    return if phone_number.blank?

    self.phone_number = ActionController::Base.helpers.sanitize(phone_number, tags: [],
                                                                              attributes: [])
  end
end
