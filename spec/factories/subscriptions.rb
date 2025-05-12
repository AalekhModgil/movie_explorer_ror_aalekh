FactoryBot.define do
  factory :subscription do
    user
    plan_type { Subscription::PLAN_TYPES.sample }
    status { Subscription::STATUSES.sample }
    stripe_customer_id { "cus_#{SecureRandom.hex(8)}" }
    stripe_subscription_id { "sub_#{SecureRandom.hex(8)}" }
    expires_at { Faker::Time.between(from: DateTime.now, to: 1.year.from_now) }

    trait :basic do
      plan_type { 'basic' }
    end

    trait :premium do
      plan_type { 'premium' }
    end

    trait :active do
      status { 'active' }
    end

    trait :inactive do
      status { 'inactive' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :invalid do
      plan_type { 'invalid_plan' }
      status { 'invalid_status' }
    end
  end
end