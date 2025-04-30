FactoryBot.define do
  factory :user do
    name { Faker::Name.name[0...100].slice(0, [3, Faker::Name.name.length].max) } 
    email { Faker::Internet.unique.email } 
    mobile_number { "+1#{Faker::Number.unique.number(digits: 10)}" } 
    password { 'password123' }
    role { :user } 
    jti { SecureRandom.uuid } 

    trait :supervisor do
      role { :supervisor }
    end
    trait :invalid do
      email { 'invalid' }
      password { '' }
      name { '' }
      mobile_number { '' }
    end
  end
end