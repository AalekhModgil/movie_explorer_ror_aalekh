class Subscription < ApplicationRecord
  belongs_to :user

  PLAN_TYPES = %w[basic premium].freeze
  STATUSES = %w[active inactive cancelled].freeze

  validates :plan_type, inclusion: { in: PLAN_TYPES }
  validates :status, inclusion: { in: STATUSES }

  def basic?; plan_type == 'basic'; end
  def premium?; plan_type == 'premium'; end

  def self.ransackable_attributes(auth_object = nil)
    %w[id user_id plan_type status created_at updated_at stripe_customer_id stripe_subscription_id expires_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end
end
