FactoryBot.define do
  factory :movie do
    title { Faker::Movie.title[0...100] }
    genre { %w[Action Comedy Drama Thriller Sci-Fi].sample }
    release_year { Faker::Number.between(from: 1881, to: Date.current.year + 1) }
    rating { Faker::Number.between(from: 0, to: 10) }
    director { Faker::Name.name }
    duration { Faker::Number.between(from: 60, to: 240) }
    description { Faker::Lorem.paragraph(sentence_count: 5)[0...1000] }
    main_lead { Faker::Name.name }
    streaming_platform { %w[Amazon Netflix Hulu Disney+ HBO].sample }
    premium { [true, false].sample }

    # Attach the poster and banner using the correct file paths
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

    trait :invalid do
      title { '' }
      genre { '' }
      release_year { 1800 } # Invalid: before 1881
      rating { 11 } # Invalid: exceeds 10
      director { '' }
      duration { 0 } # Invalid: must be > 0
      description { '' }
      main_lead { '' }
      streaming_platform { 'InvalidPlatform' } # Invalid: not in allowed list
    end

    trait :without_attachments do
      after(:build) do |movie|
        movie.poster.detach
        movie.banner.detach
      end
    end
  end
end