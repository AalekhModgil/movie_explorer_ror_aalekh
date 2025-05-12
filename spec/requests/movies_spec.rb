require 'rails_helper'

RSpec.describe 'Movies API', type: :request do
  let(:user) { create(:user) }
  let(:supervisor) { create(:user, role: 'supervisor') }
  let(:jwt_token) { "mocked_jwt_token_#{user.id}" }
  let(:supervisor_token) { "mocked_jwt_token_#{supervisor.id}" }
  let(:decoded_token) { [{ 'sub' => user.id, 'jti' => user.jti }, { 'alg' => 'HS256' }] }
  let(:supervisor_decoded_token) { [{ 'sub' => supervisor.id, 'jti' => supervisor.jti }, { 'alg' => 'HS256' }] }

  before do
    allow(JWT).to receive(:decode).with(jwt_token, anything, true, { algorithm: 'HS256' }).and_return(decoded_token)
    allow(JWT).to receive(:decode).with(supervisor_token, anything, true, { algorithm: 'HS256' }).and_return(supervisor_decoded_token)
    allow(JwtBlacklist).to receive(:exists?).and_return(false)
    allow_any_instance_of(MovieSerializer).to receive(:poster_url).and_return('http://example.com/poster.jpg')
    allow_any_instance_of(MovieSerializer).to receive(:banner_url).and_return('http://example.com/banner.jpg')
  end

  describe 'GET /api/v1/movies' do
    let!(:movies) { create_list(:movie, 15) }

    context 'without filters' do
      it 'returns paginated movies' do
        get '/api/v1/movies', as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['movies'].count).to eq(10)
        expect(json['pagination']['current_page']).to eq(1)
        expect(json['pagination']['total_pages']).to eq(2)
        expect(json['pagination']['total_count']).to eq(15)
      end
    end

    context 'with title filter' do
      let!(:movie) { create(:movie, title: 'The Matrix') }

      it 'returns movies matching title' do
        get '/api/v1/movies', params: { title: 'Matrix' }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['movies']).to be_present
        expect(json['movies'].any? { |m| m['title'] == 'The Matrix' }).to be true
      end
    end

    context 'with genre filter' do
      let!(:movie) { create(:movie, genre: 'Sci-Fi') }

      it 'returns movies matching genre' do
        get '/api/v1/movies', params: { genre: 'Sci-Fi' }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['movies']).to be_present
        expect(json['movies'].any? { |m| m['genre'] == 'Sci-Fi' }).to be true
      end
    end

    context 'when no movies found' do
      it 'returns not found status' do
        Movie.destroy_all
        get '/api/v1/movies', as: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No movies found')
      end
    end
  end

  describe 'GET /api/v1/movies/:id' do
    let!(:movie) { create(:movie) }

    context 'with valid id' do
      it 'returns the movie' do
        get "/api/v1/movies/#{movie.id}", as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['title']).to eq(movie.title)
      end
    end

    context 'with invalid id' do
      it 'returns not found status' do
        get '/api/v1/movies/999', as: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Movie not found')
      end
    end
  end

  describe 'POST /api/v1/movies' do
    let(:valid_attributes) do
      {
        movie: {
          title: 'New Movie',
          genre: 'Action',
          release_year: 2023,
          rating: 8,
          director: 'John Doe',
          duration: 120,
          description: 'A great movie',
          main_lead: 'Jane Doe',
          streaming_platform: 'Netflix',
          premium: false,
          poster: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'poster.jpg'), 'image/jpeg'),
          banner: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'banner.jpg'), 'image/jpeg')
        }
      }
    end

    let(:invalid_attributes) { { movie: attributes_for(:movie, :invalid) } }

    context 'with supervisor token' do
      before do
        allow_any_instance_of(User).to receive(:supervisor?).and_return(true)
      end

      it 'creates a new movie' do
        post '/api/v1/movies', headers: { 'Authorization' => "Bearer #{supervisor_token}" }, params: valid_attributes, as: :multipart
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Movie added successfully')
        expect(json['movie']['title']).to eq('New Movie')
      end

      it 'returns errors with invalid attributes' do
        post '/api/v1/movies', headers: { 'Authorization' => "Bearer #{supervisor_token}" }, params: invalid_attributes, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(/Title can't be blank/)
      end
    end

    context 'with non-supervisor token' do
      before do
        allow_any_instance_of(User).to receive(:supervisor?).and_return(false)
      end

      it 'returns forbidden status' do
        post '/api/v1/movies', headers: { 'Authorization' => "Bearer #{jwt_token}" }, params: valid_attributes, as: :multipart
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Forbidden: Supervisor access required')
      end
    end
  end

  describe 'PUT /api/v1/movies/:id' do
    let!(:movie) { create(:movie) }
    let(:update_attributes) do
      {
        movie: {
          title: 'Updated Movie',
          poster: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'poster.jpg'), 'image/jpeg')
        }
      }
    end

    let(:invalid_update_attributes) do
      { movie: { title: '', genre: '' } }
    end

    context 'with supervisor token' do
      before do
        allow_any_instance_of(User).to receive(:supervisor?).and_return(true)
      end

      it 'updates the movie' do
        put "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{supervisor_token}" }, params: update_attributes, as: :multipart
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['title']).to eq('Updated Movie')
      end

      it 'returns errors with invalid attributes' do
        put "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{supervisor_token}" }, params: invalid_update_attributes, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(/Title can't be blank/)
      end

      it 'returns not found if movie does not exist' do
        put '/api/v1/movies/999', headers: { 'Authorization' => "Bearer #{supervisor_token}" }, params: update_attributes, as: :multipart
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Movie not found')
      end
    end

    context 'with non-supervisor token' do
      before do
        allow_any_instance_of(User).to receive(:supervisor?).and_return(false)
      end

      it 'returns forbidden status' do
        put "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{jwt_token}" }, params: update_attributes, as: :multipart
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Forbidden: Supervisor access required')
      end
    end
  end

  describe 'DELETE /api/v1/movies/:id' do
    let!(:movie) { create(:movie) }

    context 'with supervisor token' do
      before do
        allow_any_instance_of(User).to receive(:supervisor?).and_return(true)
      end

      it 'deletes the movie' do
        delete "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{supervisor_token}" }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Movie deleted successfully')
        expect(Movie.exists?(movie.id)).to be_falsey
      end

      it 'returns not found if movie does not exist' do
        delete '/api/v1/movies/999', headers: { 'Authorization' => "Bearer #{supervisor_token}" }, as: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Movie not found')
      end
    end

    context 'with non-supervisor token' do
      before do
        allow_any_instance_of(User).to receive(:supervisor?).and_return(false)
      end

      it 'returns forbidden status' do
        delete "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{jwt_token}" }, as: :json
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Forbidden: Supervisor access required')
      end
    end
  end
end