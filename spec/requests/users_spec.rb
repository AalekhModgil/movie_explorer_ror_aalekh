require 'rails_helper'

RSpec.describe 'User Management API', type: :request do
  let(:user) { create(:user) }
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

  describe 'POST /users (Registration)' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          user: {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'password123',
            mobile_number: '+12345678901'
          }
        }
      end

      it 'creates a new user and returns status 201' do
        post '/users', params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['email']).to eq('john@example.com')
        expect(json['role']).to eq('user')
        expect(json['token']).to be_present
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          user: {
            name: '',
            email: 'invalid',
            password: '',
            mobile_number: ''
          }
        }
      end

      it 'returns status 422 with errors' do
        post '/users', params: invalid_attributes, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(/Name can't be blank/, /Email is invalid/, /Password can't be blank/, /Mobile number is invalid/)
      end
    end
  end

  describe 'POST /users/sign_in (Login)' do
    let!(:user_record) { create(:user, password: 'password123') }

    context 'with correct credentials' do
      let(:valid_credentials) do
        {
          user: {
            email: user_record.email,
            password: 'password123'
          }
        }
      end

      it 'logs in the user and returns a token' do
        allow_any_instance_of(Warden::Proxy).to receive(:authenticate!).and_return(user_record)
        allow_any_instance_of(Warden::Proxy).to receive(:authenticated?).and_return(false)

        post '/users/sign_in', params: valid_credentials, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['email']).to eq(user_record.email)
        expect(json['token']).to be_present
      end
    end
  end

  describe 'DELETE /users/sign_out (Logout)' do
    context 'with no token' do
      it 'returns unauthorized status' do
        delete '/users/sign_out', as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No token provided. Please include a valid Bearer token.')
      end
    end
  end

  describe 'GET /api/v1/current_user' do
    context 'with valid token' do
      it 'returns the current user' do
        get '/api/v1/current_user', headers: { 'Authorization' => "Bearer #{jwt_token}" }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['email']).to eq(user.email)
        expect(json['role']).to eq(user.role)
      end
    end

    context 'with no token' do
      it 'returns unauthorized status' do
        get '/api/v1/current_user', as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No token provided. Please sign in.')
      end
    end
  end

  describe 'POST /api/v1/update_device_token' do
    context 'with valid token and device token' do
      let(:device_token_params) { { device_token: SecureRandom.hex(32) } }

      it 'updates the device token' do
        post '/api/v1/update_device_token', headers: { 'Authorization' => "Bearer #{jwt_token}" }, params: device_token_params, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Device token updated successfully')
        expect(user.reload.device_token).to eq(device_token_params[:device_token])
      end
    end
  end

  describe 'POST /api/v1/toggle_notifications' do
    context 'with valid token and notifications enabled' do
      let(:notification_params) { { notifications_enabled: 'true' } }

      it 'enables notifications' do
        user.update(notifications_enabled: false)
        post '/api/v1/toggle_notifications', headers: { 'Authorization' => "Bearer #{jwt_token}" }, params: notification_params, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Notification preference updated')
        expect(json['notifications_enabled']).to be true
        expect(user.reload.notifications_enabled).to be true
      end
    end

    context 'with valid token and notifications disabled' do
      let(:notification_params) { { notifications_enabled: 'false' } }

      it 'disables notifications' do
        user.update(notifications_enabled: true)
        post '/api/v1/toggle_notifications', headers: { 'Authorization' => "Bearer #{jwt_token}" }, params: notification_params, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Notification preference updated')
        expect(json['notifications_enabled']).to be false
        expect(user.reload.notifications_enabled).to be false
      end
    end
  end
end