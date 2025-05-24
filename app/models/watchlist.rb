class Watchlist < ApplicationRecord
  belongs_to :user
  belongs_to :movie

  validates :user_id, uniqueness: { scope: :movie_id, message: "Movie is already in your watchlist" }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "movie_id", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["movie", "user"]
  end
end