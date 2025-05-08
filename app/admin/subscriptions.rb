ActiveAdmin.register Subscription do
  permit_params :user_id, :plan_type, :status, :expires_at, :stripe_customer_id, :stripe_subscription_id

  index do
    selectable_column
    id_column
    column :user do |subscription|
      subscription.user&.name || subscription.user&.email || "N/A"
    end
    column :plan_type
    column :status
    column :expires_at
    column :stripe_customer_id
    column :stripe_subscription_id
    actions
  end

  filter :user, as: :select, collection: proc { User.pluck(:name, :id) }
  filter :plan_type, as: :select, collection: Subscription::PLAN_TYPES
  filter :status, as: :select, collection: Subscription::STATUSES
  filter :expires_at

  form do |f|
    f.inputs do
      f.input :user, as: :select, collection: User.pluck(:name, :id)
      f.input :plan_type, as: :select, collection: Subscription::PLAN_TYPES
      f.input :status, as: :select, collection: Subscription::STATUSES
      f.input :expires_at, as: :datepicker
      f.input :stripe_customer_id
      f.input :stripe_subscription_id
    end
    f.actions
  end
end