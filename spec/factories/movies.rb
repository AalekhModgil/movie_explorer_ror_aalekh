FactoryBot.define do
  factory :movie do
    title { Faker::Movie.title }
    genre { Faker::Book.genre }
    release_year { Faker::Number.between(from: 1881, to: Date.current.year + 1) }
    rating { Faker::Number.between(from: 0, to: 10) }
    director { Faker::Name.name }
    duration { Faker::Number.between(from: 1, to: 300) } 
    description { Faker::Lorem.paragraph_by_chars(number: 500, supplemental: false) } 
    premium { false }

    poster do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'fixtures', 'files', 'poster.jpg'),
        'image/jpg'
      )
    end

    banner do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'fixtures', 'files', 'banner.png'),
        'image/jpg'
      )
    end

    trait :premium do
      premium { true }
    end

    trait :without_poster do
      poster { nil }
    end

    trait :without_banner do
      banner { nil }
    end
  end
end