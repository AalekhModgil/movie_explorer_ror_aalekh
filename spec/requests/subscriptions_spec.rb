require 'rails_helper'

RSpec.describe 'Subscriptions API', type: :request do
  let(:user) { create(:user) }
  let(:subscription) { create(:subscription, user: user, stripe_customer_id: 'stripe_customer_id', plan_type: 'basic', status: 'inactive') }
  let(:jwt_token) { "mocked_jwt_token_#{user.id}" }
  let(:decoded_token) { [{ 'sub' => user.id, 'jti' => user.jti, 'role' => user.role, 'scp' => 'user' }, { 'alg' => 'HS256' }] }

  before do
    allow(JWT).to receive(:decode).with(jwt_token, anything, true, { algorithm: 'HS256' }).and_return(decoded_token)
    allow(JwtBlacklist).to receive(:exists?).and_return(false)
    allow(JwtBlacklist).to receive(:revoked?).and_return(false)
    allow(JwtBlacklist).to receive(:revoke)
  end

  before do
    allow(Stripe::Customer).to receive(:create).and_return(double(id: 'stripe_customer_id'))
  end

  describe 'POST /api/v1/subscriptions (Create Subscription)' do
    let(:valid_params) { { plan_type: '1_month' } }
    let(:invalid_params) { { plan_type: 'invalid_plan' } }
    let(:stripe_session) do
      double(
        id: 'session_id',
        url: 'https://checkout.stripe.com/session',
        customer: 'stripe_customer_id',
        subscription: 'stripe_subscription_id',
        metadata: OpenStruct.new(plan_type: '1_month')
      )
    end

    context 'with valid token and parameters' do
      before do
        allow(Stripe::Checkout::Session).to receive(:create).and_return(stripe_session)
      end

      it 'creates a Stripe checkout session and returns session details' do
        post '/api/v1/subscriptions', headers: { 'Authorization' => "Bearer #{jwt_token}" }, params: valid_params, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['session_id']).to eq('session_id')
        expect(json['url']).to eq('https://checkout.stripe.com/session')
      end
    end

    context 'with valid token and invalid plan type' do
      it 'returns a bad request error' do
        post '/api/v1/subscriptions', headers: { 'Authorization' => "Bearer #{jwt_token}" }, params: invalid_params, as: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid plan type')
      end
    end

    context 'with no token' do
      it 'returns unauthorized status' do
        post '/api/v1/subscriptions', params: valid_params, as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No token provided. Please sign in.')
      end
    end
  end

  describe 'GET /api/v1/subscriptions/success (Subscription Success)' do
    let(:session_id) { 'session_id' }
    let(:stripe_session) do
      double(
        customer: subscription.stripe_customer_id,
        subscription: 'stripe_subscription_id',
        metadata: OpenStruct.new(plan_type: '1_month')
      )
    end

    before do
      allow(Stripe::Checkout::Session).to receive(:retrieve).with(session_id).and_return(stripe_session)
    end

    context 'with valid session and subscription' do
      it 'updates the subscription and returns success message' do
        expect {
          get "/api/v1/subscriptions/success", params: { session_id: session_id }, as: :json
        }.to change { subscription.reload.plan_type }.from('basic').to('premium')
        .and change { subscription.status }.from('inactive').to('active')
        .and change { subscription.stripe_subscription_id }.to('stripe_subscription_id')
        .and change { subscription.expires_at }.to(be_within(1.minute).of(1.month.from_now))

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Subscription updated successfully')
      end
    end

    context 'with invalid session (no subscription found)' do
      before do
        allow(Stripe::Checkout::Session).to receive(:retrieve).with(session_id).and_return(
          double(customer: 'unknown_customer', subscription: nil, metadata: OpenStruct.new(plan_type: '1_month'))
        )
      end

      it 'returns not found error' do
        get "/api/v1/subscriptions/success", params: { session_id: session_id }, as: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Subscription not found')
      end
    end
  end

  describe 'GET /api/v1/subscriptions/cancel (Subscription Cancel)' do
    it 'returns cancellation message' do
      get '/api/v1/subscriptions/cancel', as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Payment cancelled')
    end
  end

  describe 'GET /api/v1/subscriptions/status (Subscription Status)' do
    context 'with valid token and no subscription' do
      before { user.subscription.destroy if user.subscription }

      it 'returns not found error' do
        get '/api/v1/subscriptions/status', headers: { 'Authorization' => "Bearer #{jwt_token}" }, as: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No active subscription found')
      end
    end

    context 'with no token' do
      it 'returns unauthorized status' do
        get '/api/v1/subscriptions/status', as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No token provided. Please sign in.')
      end
    end
  end
end