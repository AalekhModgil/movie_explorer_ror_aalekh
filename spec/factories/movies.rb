FactoryBot.define do
  factory :movie do
    title { Faker::Movie.title[0...100] }
    genre { %w[Action Comedy Drama Thriller Sci-Fi].sample }
    release_year { Faker::Number.between(from: 1881, to: Date.current.year + 1) }
    rating { Faker::Number.between(from: 0, to: 10) }
    director { Faker::Name.name }
    duration { Faker::Number.between(from: 60, to: 240) }
    streaming_platform { %w[Amazon Netflix Hulu Disney+ HBO].sample }
    main_lead { Faker::Name.name }
    description { Faker::Lorem.paragraph(sentence_count: 5)[0...1000] }
    premium { false }

    # Trait for premium movies
    trait :premium do
      premium { true }
    end

    # Trait for invalid movie data
    trait :invalid do
      title { '' }
      genre { '' }
      release_year { 1800 } # Invalid: before 1881
      rating { 11 } # Invalid: greater than 10
      director { '' }
      duration { 0 } # Invalid: must be greater than 0
      streaming_platform { 'InvalidPlatform' }
      main_lead { '' }
      description { '' }
    end

    # Trait to attach poster and banner
    trait :with_attachments do
      after(:build) do |movie|
        movie.poster.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'poster.jpg')),
          filename: 'poster.jpg',
          content_type: 'image/jpeg'
        )
        movie.banner.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'banner.jpg')),
          filename: 'banner.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
  end
end