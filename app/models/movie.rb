class Movie < ApplicationRecord
  has_one_attached :poster
  has_one_attached :banner

  validates :title, presence: true
  validates :genre, presence: true
  validates :release_year, numericality: { only_integer: true, greater_than: 1880, less_than_or_equal_to: Date.current.year + 1 }
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :director, presence: true
  validates :duration, numericality: { only_integer: true, greater_than: 0 }
  validates :streaming_platform, presence: true, inclusion: { in: %w[Amazon Netflix Hulu Disney+ HBO], message: "%{value} is not a valid streaming platform" }
  validates :main_lead, presence: true
  validates :description, presence: true, length: { maximum: 1000 }
  validate :poster_content_type, if: :poster_attached?
  validate :banner_content_type, if: :banner_attached?

  scope :premium, -> { where(premium: true) }
  scope :accessible_to_user, ->(user) { user&.premium_access ? all : where(premium: false) }

  def poster_attached?
    poster.attached?
  end

  def banner_attached?
    banner.attached?
  end

  private

  def poster_content_type
    unless poster.content_type.in?(%w[image/jpeg image/png])
      errors.add(:poster, 'must be a JPEG or PNG image')
    end
  end

  def banner_content_type
    unless banner.content_type.in?(%w[image/jpeg image/png])
      errors.add(:banner, 'must be a JPEG or PNG image')
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "director", "duration", "genre", "id", "id_value", "main_lead", "premium", "rating", "release_year", "streaming_platform", "title", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["banner_attachment", "banner_blob", "poster_attachment", "poster_blob"]
  end
end
