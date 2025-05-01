require 'rails_helper'

RSpec.describe Movie, type: :model do
  let(:movie) { build(:movie) }
  let(:invalid_movie) { build(:movie, :invalid) }
  let(:movie_without_attachments) { build(:movie, :without_attachments) }

  # Test validations
  describe "validations" do
    it "is valid with valid attributes" do
      expect(movie).to be_valid
    end

    it "is not valid without a title" do
      movie.title = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:title]).to include("can't be blank")
    end

    it "is not valid without a genre" do
      movie.genre = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:genre]).to include("can't be blank")
    end

    it "is not valid with an invalid release year" do
      movie.release_year = 1800
      expect(movie).not_to be_valid
      expect(movie.errors[:release_year]).to include("must be greater than 1880")
    end

    it "is not valid with a future release year beyond next year" do
      movie.release_year = Date.current.year + 2
      expect(movie).not_to be_valid
      expect(movie.errors[:release_year]).to include("must be less than or equal to #{Date.current.year + 1}")
    end

    it "is valid with a rating within range" do
      movie.rating = 5
      expect(movie).to be_valid
    end

    it "is not valid with a rating above 10" do
      movie.rating = 11
      expect(movie).not_to be_valid
      expect(movie.errors[:rating]).to include("must be less than or equal to 10")
    end

    it "is not valid with a rating below 0" do
      movie.rating = -1
      expect(movie).not_to be_valid
      expect(movie.errors[:rating]).to include("must be greater than or equal to 0")
    end

    it "is valid with nil rating" do
      movie.rating = nil
      expect(movie).to be_valid
    end

    it "is not valid without a director" do
      movie.director = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:director]).to include("can't be blank")
    end

    it "is not valid with a duration of 0 or less" do
      movie.duration = 0
      expect(movie).not_to be_valid
      expect(movie.errors[:duration]).to include("must be greater than 0")
    end

    it "is not valid without a streaming platform" do
      movie.streaming_platform = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:streaming_platform]).to include("can't be blank")
    end

    it "is not valid with an invalid streaming platform" do
      movie.streaming_platform = "InvalidPlatform"
      expect(movie).not_to be_valid
      expect(movie.errors[:streaming_platform]).to include("InvalidPlatform is not a valid streaming platform")
    end

    it "is not valid without a main lead" do
      movie.main_lead = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:main_lead]).to include("can't be blank")
    end

    it "is not valid without a description" do
      movie.description = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:description]).to include("can't be blank")
    end

    it "is not valid if description exceeds 1000 characters" do
      movie.description = "a" * 1001
      expect(movie).not_to be_valid
      expect(movie.errors[:description]).to include("is too long (maximum is 1000 characters)")
    end

    it "is not valid with invalid attributes" do
      expect(invalid_movie).not_to be_valid
      expect(invalid_movie.errors[:title]).to include("can't be blank")
      expect(invalid_movie.errors[:genre]).to include("can't be blank")
      expect(invalid_movie.errors[:release_year]).to include("must be greater than 1880")
      expect(invalid_movie.errors[:rating]).to include("must be less than or equal to 10")
      expect(invalid_movie.errors[:director]).to include("can't be blank")
      expect(invalid_movie.errors[:duration]).to include("must be greater than 0")
      expect(invalid_movie.errors[:description]).to include("can't be blank")
      expect(invalid_movie.errors[:main_lead]).to include("can't be blank")
      expect(invalid_movie.errors[:streaming_platform]).to include("InvalidPlatform is not a valid streaming platform")
    end

    it "is valid without poster attachment" do
      expect(movie_without_attachments).to be_valid
    end

    it "is not valid with invalid poster content type" do
      movie.poster.attach(io: StringIO.new("invalid"), filename: "invalid.txt", content_type: "text/plain")
      expect(movie).not_to be_valid
      expect(movie.errors[:poster]).to include("must be a JPEG or PNG image")
    end

    it "is valid without banner attachment" do
      expect(movie_without_attachments).to be_valid
    end

    it "is not valid with invalid banner content type" do
      movie.banner.attach(io: StringIO.new("invalid"), filename: "invalid.txt", content_type: "text/plain")
      expect(movie).not_to be_valid
      expect(movie.errors[:banner]).to include("must be a JPEG or PNG image")
    end
  end

  # Test scopes
  describe "scopes" do
    it "filters premium movies" do
      premium_movie = create(:movie, premium: true)
      regular_movie = create(:movie, premium: false)
      expect(Movie.premium).to include(premium_movie)
      expect(Movie.premium).not_to include(regular_movie)
    end
  end
end