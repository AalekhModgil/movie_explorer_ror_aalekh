module Api
  module V1
    class MoviesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!, only: [:create, :update, :destroy]
      before_action :ensure_supervisor, only: [:create, :update, :destroy]

      def index
        movies = Movie.all

        if params[:title].present?
          movies = movies.where("title ILIKE ?", "%#{params[:title]}%")
        end

        if params[:genre].present?
          movies = movies.where(genre: params[:genre])
        end

        movies = movies.page(params[:page] || 1).per(params[:per_page] || 10)

        if movies.empty?
          render json: { error: "No movies found" }, status: :not_found
        else
          serialized = movies.map { |movie| ::MovieSerializer.new(movie).serializable_hash }
          render json: {
            movies: serialized,
            pagination: {
              current_page: movies.current_page,
              total_pages: movies.total_pages,
              total_count: movies.total_count,
              per_page: movies.limit_value
            }
          }, status: :ok
        end
      end

      def show
        movie = Movie.find_by(id: params[:id])
        if movie
          render json: ::MovieSerializer.new(movie).serializable_hash, status: :ok
        else
          render json: { error: "Movie not found" }, status: :not_found
        end
      end

      def create
        movie = Movie.new(movie_params.except(:poster, :banner))
        attach_files(movie)

        if movie.save
          render json: {
            message: "Movie added successfully",
            movie: ::MovieSerializer.new(movie).serializable_hash
          }, status: :created
        else
          render json: { errors: movie.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        movie = Movie.find_by(id: params[:id])
        if movie.nil?
          render json: { error: "Movie not found" }, status: :not_found
        else
          attach_files(movie)
          if movie.update(movie_params.except(:poster, :banner))
            render json: ::MovieSerializer.new(movie).serializable_hash
          else
            render json: { errors: movie.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        movie = Movie.find_by(id: params[:id])
        if movie
          movie.destroy
          head :no_content
        else
          render json: { error: "Movie not found" }, status: :not_found
        end
      end

      private

      def movie_params
        params.require(:movie).permit(
          :title, :genre, :release_year, :rating, :director,
          :duration, :description,:main_lead,:streaming_platform, :premium, :poster, :banner
        )
      end

      def attach_files(movie)
        if params[:movie][:poster].present? && params[:movie][:poster].is_a?(ActionDispatch::Http::UploadedFile)
          movie.poster.attach(params[:movie][:poster])
        end

        if params[:movie][:banner].present? && params[:movie][:banner].is_a?(ActionDispatch::Http::UploadedFile)
          movie.banner.attach(params[:movie][:banner])
        end
      end

      def ensure_supervisor
        unless current_user.supervisor?
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
    end
  end
end