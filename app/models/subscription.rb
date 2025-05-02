class Subscription < ApplicationRecord
  belongs_to :user

  PLAN_TYPES = %w[free basic premium].freeze
  STATUSES = %w[active inactive cancelled].freeze

  validates :plan_type, inclusion: { in: PLAN_TYPES }
  validates :status, inclusion: { in: STATUSES }

  def free?; plan_type == 'free'; end
  def basic?; plan_type == 'basic'; end
  def premium?; plan_type == 'premium'; end
end
