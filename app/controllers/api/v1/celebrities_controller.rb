# app/controllers/api/v1/celebrities_controller.rb
module Api
  module V1
    class CelebritiesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!, only: [:create, :update, :destroy]
      before_action :ensure_supervisor, only: [:create, :update, :destroy]

      def index
        celebrities = Celebrity.all
        if params[:name].present?
          celebrities = celebrities.where("name ILIKE ?", "%#{params[:name]}%")
        end
        celebrities = celebrities.page(params[:page] || 1).per(params[:per_page] || 10)
        if celebrities.empty?
          render json: { errors: ["No celebrities found"] }, status: :not_found
        else
          render json: {
            data: ActiveModelSerializers::SerializableResource.new(
              celebrities,
              each_serializer: CelebritySerializer
            ).as_json,
            meta: {
              pagination: {
                current_page: celebrities.current_page,
                total_pages: celebrities.total_pages,
                total_count: celebrities.total_count,
                per_page: celebrities.limit_value
              }
            }
          }, status: :ok
        end
      end

      def show
        celebrity = Celebrity.find_by(id: params[:id])
        if celebrity
          render json: CelebritySerializer.new(celebrity).as_json, status: :ok
        else
          render json: { errors: ["Celebrity not found"] }, status: :not_found
        end
      end

      def create
        celebrity = Celebrity.new(celebrity_params.except(:image, :movie_ids))
        attach_image(celebrity)
        if celebrity_params[:movie_ids].present?
          return render json: { errors: ["Invalid movie_ids: #{invalid_movie_ids(celebrity_params[:movie_ids]).join(', ')}"] }, status: :unprocessable_entity unless valid_movie_ids?(celebrity_params[:movie_ids])
          celebrity.movie_ids = celebrity_params[:movie_ids]
        end
        if celebrity.save
          render json: {
            message: "Celebrity added successfully",
            celebrity: CelebritySerializer.new(celebrity).as_json
          }, status: :created
        else
          render json: { errors: celebrity.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        celebrity = Celebrity.find_by(id: params[:id])
        if celebrity.nil?
          render json: { errors: ["Celebrity not found"] }, status: :not_found
        else
          attach_image(celebrity)
          current_movie_ids = celebrity.movie_ids

          # Handle adding movie_ids
          if celebrity_params[:movie_ids].present?
            return render json: { errors: ["Invalid movie_ids: #{invalid_movie_ids(celebrity_params[:movie_ids]).join(', ')}"] }, status: :unprocessable_entity unless valid_movie_ids?(celebrity_params[:movie_ids])
            new_movie_ids = celebrity_params[:movie_ids].map(&:to_i)
            duplicates = new_movie_ids & current_movie_ids
            return render json: { errors: ["Movie IDs already associated: #{duplicates.join(', ')}"] }, status: :unprocessable_entity if duplicates.any?
            celebrity.movie_ids = (current_movie_ids + new_movie_ids).uniq
          end

          # Handle removing movie_ids
          if celebrity_params[:remove_movie_ids].present?
            return render json: { errors: ["Invalid remove_movie_ids: #{invalid_remove_movie_ids.join(', ')}"] }, status: :unprocessable_entity unless valid_movie_ids?(celebrity_params[:remove_movie_ids])
            remove_ids = celebrity_params[:remove_movie_ids].map(&:to_i)
            unassociated_ids = remove_ids - current_movie_ids
            return render json: { errors: ["Cannot remove unassociated movie IDs: #{unassociated_ids.join(', ')}"] }, status: :unprocessable_entity if unassociated_ids.any?
            celebrity.movie_ids -= remove_ids
          end

          if celebrity.update(celebrity_params.except(:movie_ids, :remove_movie_ids, :image))
            render json: CelebritySerializer.new(celebrity).as_json, status: :ok
          else
            render json: { errors: celebrity.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        celebrity = Celebrity.find_by(id: params[:id])
        if celebrity
          celebrity.destroy
          render json: { message: "Celebrity deleted successfully" }, status: :ok
        else
          render json: { errors: ["Celebrity not found"] }, status: :not_found
        end
      end

      private

      def celebrity_params
        params.require(:celebrity).permit(:name, :birth_date, :nationality, :biography, :image, movie_ids: [], remove_movie_ids: [])
      end

      def attach_image(celebrity)
        if params[:celebrity][:image].present? && params[:celebrity][:image].is_a?(ActionDispatch::Http::UploadedFile)
          celebrity.image.attach(params[:celebrity][:image])
        end
      end

      def ensure_supervisor
        unless @current_user&.supervisor?
          render json: { errors: ["Forbidden: Supervisor access required"] }, status: :forbidden
        end
      end

      def valid_movie_ids?(movie_ids)
        invalid_movie_ids(movie_ids).empty?
      end

      def invalid_movie_ids(movie_ids)
        provided_ids = movie_ids.map(&:to_i)
        valid_ids = Movie.where(id: provided_ids).pluck(:id)
        provided_ids - valid_ids
      end

      def invalid_remove_movie_ids
        @invalid_remove_movie_ids ||= invalid_movie_ids(celebrity_params[:remove_movie_ids])
      end
    end
  end
end