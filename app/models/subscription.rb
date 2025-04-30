class Subscription < ApplicationRecord
  belongs_to :user

  PLAN_TYPES = %w[free basic premium].freeze
  STATUSES = %w[active inactive cancelled].freeze

  validates :plan_type, inclusion: { in: PLAN_TYPES }
  validates :status, inclusion: { in: STATUSES }

  
end
