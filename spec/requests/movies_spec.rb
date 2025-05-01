require 'rails_helper'

RSpec.describe 'Api::V1::Movies', type: :request do
  let(:supervisor) { create(:user, :supervisor) }
  let(:regular_user) { create(:user) }
  let(:movie) { create(:movie) }
  let(:valid_attributes) do
    attributes_for(:movie).merge(
      poster: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'poster.jpg'), 'image/jpeg'),
      banner: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'banner.jpg'), 'image/jpeg')
    )
  end
  let(:invalid_attributes) do
    attributes_for(:movie, :invalid).merge(
      poster: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'poster.jpg'), 'image/jpeg'),
      banner: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'banner.jpg'), 'image/jpeg')
    )
  end

  describe 'GET /api/v1/movies' do
    context 'when movies exist' do
      let!(:movies) { create_list(:movie, 15) }

      it 'returns a paginated list of movies' do
        get '/api/v1/movies', params: { page: 1, per_page: 10 }, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['movies'].size).to eq(10)
        expect(data['pagination']['current_page']).to eq(1)
        expect(data['pagination']['total_pages']).to eq(2)
        expect(data['pagination']['total_count']).to eq(15)
      end

      it 'filters movies by title' do
        create(:movie, title: 'The Matrix')
        get '/api/v1/movies', params: { title: 'Matrix' }, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['movies'].size).to eq(1)
        expect(data['movies'].first['title']).to eq('The Matrix')
      end

      it 'filters movies by genre' do
        create(:movie, genre: 'Sci-Fi')
        get '/api/v1/movies', params: { genre: 'Sci-Fi' }, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['movies'].size).to eq(1)
        expect(data['movies'].first['genre']).to eq('Sci-Fi')
      end
    end

    context 'when no movies match the filters' do
      it 'returns not found status' do
        get '/api/v1/movies', params: { title: 'Nonexistent' }, as: :json
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('No movies found')
      end
    end
  end

  describe 'GET /api/v1/movies/:id' do
    context 'when the movie exists' do
      it 'returns the movie' do
        get "/api/v1/movies/#{movie.id}", as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['title']).to eq(movie.title)
      end
    end

    context 'when the movie does not exist' do
      it 'returns not found status' do
        get '/api/v1/movies/999', as: :json
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Movie not found')
      end
    end
  end

  describe 'POST /api/v1/movies' do
    context 'when user is a supervisor' do
      before { sign_in supervisor }

      it 'creates a new movie with valid attributes' do
        post '/api/v1/movies', params: { movie: valid_attributes }, as: :json
        expect(response).to have_http_status(:created)
        data = JSON.parse(response.body)
        expect(data['message']).to eq('Movie added successfully')
        expect(data['movie']['title']).to eq(valid_attributes[:title])
      end

      it 'returns errors with invalid attributes' do
        post '/api/v1/movies', params: { movie: invalid_attributes }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end

    context 'when user is not a supervisor' do
      before { sign_in regular_user }

      it 'returns unauthorized status' do
        post '/api/v1/movies', params: { movie: valid_attributes }, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end

    context 'when user is not signed in' do
      it 'returns unauthorized status' do
        post '/api/v1/movies', params: { movie: valid_attributes }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/movies/:id' do
    context 'when user is a supervisor' do
      before { sign_in supervisor }

      it 'updates the movie with valid attributes' do
        patch "/api/v1/movies/#{movie.id}", params: { movie: { title: 'Updated Title' } }, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['title']).to eq('Updated Title')
      end

      it 'returns errors with invalid attributes' do
        patch "/api/v1/movies/#{movie.id}", params: { movie: invalid_attributes }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('errors')
      end

      it 'returns not found if movie does not exist' do
        patch '/api/v1/movies/999', params: { movie: valid_attributes }, as: :json
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Movie not found')
      end
    end

    context 'when user is not a supervisor' do
      before { sign_in regular_user }

      it 'returns unauthorized status' do
        patch "/api/v1/movies/#{movie.id}", params: { movie: valid_attributes }, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'DELETE /api/v1/movies/:id' do
    context 'when user is a supervisor' do
      before { sign_in supervisor }

      it 'deletes the movie' do
        delete "/api/v1/movies/#{movie.id}", as: :json
        expect(response).to have_http_status(:no_content)
        expect(Movie.find_by(id: movie.id)).to be_nil
      end

      it 'returns not found if movie does not exist' do
        delete '/api/v1/movies/999', as: :json
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Movie not found')
      end
    end

    context 'when user is not a supervisor' do
      before { sign_in regular_user }

      it 'returns unauthorized status' do
        delete "/api/v1/movies/#{movie.id}", as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end
  end
end