module Api
  module V1
    class WatchlistsController < ApplicationController
      before_action :authenticate_user!
      skip_before_action :verify_authenticity_token
      before_action :set_watchlist, only: [:destroy]

      def index
        @watchlists = @current_user.watchlist_movies.accessible_to_user(@current_user)
        if @watchlists.any?
          serialized = @watchlists.map { |movie| WatchlistSerializer.new(movie).serializable_hash }
          render json: { message: "Watchlist retrieved successfully", data: serialized }, status: :ok
        else
          render json: { message: "Your watchlist is empty", data: [] }, status: :ok
        end
      end

      def create
        movie = Movie.find_by(id: params[:movie_id])
        if movie
          if Movie.accessible_to_user(@current_user).where(id: movie.id).exists?
            @watchlist = @current_user.watchlists.new(movie_id: params[:movie_id])
            if @watchlist.save
              render json: { 
                message: "Movie added to watchlist", 
                data: WatchlistSerializer.new(@watchlist.movie).serializable_hash 
              }, status: :created
            else
              render json: { errors: @watchlist.errors.full_messages }, status: :unprocessable_entity
            end
          else
            render json: { errors: ["Movie is not accessible to your subscription"] }, status: :forbidden
          end
        else
          render json: { errors: ["Movie not found"] }, status: :not_found
        end
      end

      def destroy
        if @watchlist.destroy
          render json: { message: "Movie removed from watchlist" }, status: :ok
        else
          render json: { errors: @watchlist.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_watchlist
        @watchlist = @current_user.watchlists.find_by(movie_id: params[:id])
        unless @watchlist
          render json: { error: "Movie not found in your watchlist" }, status: :not_found
        end
      end
    end
  end
end