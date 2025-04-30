require 'rails_helper'

RSpec.describe 'User Authentication', type: :request do
  describe 'POST /users' do
    context 'with valid parameters' do
      let(:valid_attributes) { { user: attributes_for(:user) } }

      it 'creates a new user and returns status 201' do
        post '/users', params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include('email' => valid_attributes[:user][:email])
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { user: attributes_for(:user, :invalid) } }

      it 'returns status 422 with errors' do
        post '/users', params: invalid_attributes, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end
  end

  describe 'POST /users/sign_in' do
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
        post '/users/sign_in', params: valid_credentials, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['email']).to eq(user_record.email)
        expect(data['token']).not_to be_nil
      end
    end

    context 'with incorrect credentials' do
      let(:invalid_credentials) do
        {
          user: {
            email: 'wrong@example.com',
            password: 'wrongpass'
          }
        }
      end

      it 'returns unauthorized status' do
        post '/users/sign_in', params: invalid_credentials, as: :json
        expect(response).to have_http_status(:unauthorized)
        data = JSON.parse(response.body)
        expect(data['error']).to eq('Invalid Email or password.')
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    it 'logs out the user and returns no content status' do
      delete '/users/sign_out'
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'GET /api/v1/current_user' do
    context 'when user is signed in' do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it 'returns the current user' do
        get '/api/v1/current_user'
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['email']).to eq(user.email)
      end
    end

    context 'when user is not signed in' do
      it 'returns unauthorized status' do
        get '/api/v1/current_user'
        expect(response).to have_http_status(:found)
      end
    end
  end
end