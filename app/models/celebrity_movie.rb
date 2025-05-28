class CelebrityMovie < ApplicationRecord
  belongs_to :celebrity
  belongs_to :movie

  validates :celebrity_id, uniqueness: { scope: :movie_id, message: "This celebrity is already associated with this movie" }

  def self.ransackable_attributes(auth_object = nil)
    ["celebrity_id", "movie_id", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["celebrity", "movie"]
  end
end