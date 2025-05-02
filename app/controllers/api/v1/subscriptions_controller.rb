class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:success]
  skip_before_action :verify_authenticity_token

  def create
    subscription = current_user.subscription
    plan_type = params[:plan_type]
    return render json: { error: 'Invalid plan type' }, status: :bad_request unless %w[basic premium].include?(plan_type)
    price_id = case plan_type
               when 'basic'
                 'price_1RJzzhPwmKg08vVsikRVrObY'
               when 'premium'
                 'price_1RK00OPwmKg08vVsRalzKgtr'
               end

    session = Stripe::Checkout::Session.create(
      customer: subscription.stripe_customer_id,
      payment_method_types: ['card'],
      line_items: [{ price: price_id, quantity: 1 }],
      mode: 'subscription',
      metadata: {
        user_id: current_user.id,
        plan_type: plan_type
      },
      success_url: "http://localhost:3000/api/v1/subscriptions/success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "http://localhost:3000/api/v1/subscriptions/cancel"
    )

    render json: { session_id: session.id, url: session.url }, status: :ok
    return
  end

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    subscription = Subscription.find_by(stripe_customer_id: session.customer)
  
    if subscription
      plan_type = session.metadata.plan_type
      subscription.update(stripe_subscription_id: session.subscription, plan_type: plan_type, status: 'active')
      render json: { message: 'Subscription updated successfully' }, status: :ok
    else
      render json: { error: 'Subscription not found' }, status: :not_found
    end
  end

  def cancel
    render json: { message: 'Payment cancelled' }, status: :ok
  end

  def index
    subscriptions = current_user.subscriptions
    render json: { subscriptions: subscriptions }, status: :ok
  end

  def show
    render json: { subscription: @subscription }, status: :ok
  end
end