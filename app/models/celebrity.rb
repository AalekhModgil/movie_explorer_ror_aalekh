class Celebrity < ApplicationRecord
  has_one_attached :image
  has_many :celebrity_movies, dependent: :destroy
  has_many :movies, through: :celebrity_movies

  validates :name, presence: true
  validates :birth_date, presence: true
  validates :nationality, presence: true
  validates :biography, presence: true, length: { maximum: 1000 }
  validates :image, presence: true
  validate :image_content_type, if: :image_attached?
  validate :valid_movie_ids, if: -> { movie_ids.present? }

  def age
    return unless birth_date
    today = Date.today
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end

  def self.ransackable_associations(auth_object = nil)
    ["image_attachment", "image_blob"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name", "birth_date", "nationality", "biography", "created_at", "updated_at"]
  end

  private

  def image_attached?
    image.attached?
  end

  def image_content_type
    unless image.content_type.in?(%w[image/jpeg image/png])
      errors.add(:image, 'must be a JPEG or PNG image')
    end
  end

  def valid_movie_ids
    invalid_ids = movie_ids - Movie.where(id: movie_ids).pluck(:id)
    errors.add(:movie_ids, "contains invalid IDs: #{invalid_ids.join(', ')}") if invalid_ids.any?
  end

end