FactoryBot.define do
  factory :user do
    name { Faker::Name.name[0...100].slice(0, [3, Faker::Name.name.length].max) }
    email { Faker::Internet.unique.email }
    mobile_number { "+1#{Faker::Number.unique.number(digits: 10)}" }
    password { 'Password1!' } # Updated to meet validation requirements
    role { :user }
    jti { SecureRandom.uuid }
    device_token { nil }
    notifications_enabled { true }

    trait :supervisor do
      role { :supervisor }
    end

    trait :invalid do
      email { 'invalid' }
      password { 'invalid' } # Updated to an invalid password
      name { '' }
      mobile_number { '' }
    end

    trait :with_invalid_password do
      password { 'password' } # No uppercase, no special character, no digit
    end

    trait :with_device_token do
      device_token { SecureRandom.hex(32) }
    end

    trait :notifications_disabled do
      notifications_enabled { false }
    end
  end
end