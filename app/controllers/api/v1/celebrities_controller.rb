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
          render json: { error: "No celebrities found" }, status: :not_found
        else
          serialized = celebrities.map { |celebrity| CelebritySerializer.new(celebrity).serializable_hash }
          render json: {
            celebrities: serialized,
            pagination: {
              current_page: celebrities.current_page,
              total_pages: celebrities.total_pages,
              total_count: celebrities.total_count,
              per_page: celebrities.limit_value
            }
          }, status: :ok
        end
      end

      def show
        celebrity = Celebrity.find_by(id: params[:id])
        if celebrity
          render json: CelebritySerializer.new(celebrity).serializable_hash, status: :ok
        else
          render json: { error: "Celebrity not found" }, status: :not_found
        end
      end

      def create
        celebrity = Celebrity.new(celebrity_params.except(:image))
        attach_image(celebrity)
        if celebrity.save
          render json: {
            message: "Celebrity added successfully",
            celebrity: CelebritySerializer.new(celebrity).serializable_hash
          }, status: :created
        else
          render json: { errors: celebrity.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        celebrity = Celebrity.find_by(id: params[:id])
        if celebrity.nil?
          render json: { error: "Celebrity not found" }, status: :not_found
        else
          attach_image(celebrity)
          if celebrity.update(celebrity_params.except(:image))
            render json: CelebritySerializer.new(celebrity).serializable_hash, status: :ok
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
          render json: { error: "Celebrity not found" }, status: :not_found
        end
      end

      private

      def celebrity_params
        params.require(:celebrity).permit(:name, :birth_date, :nationality, :biography, :image)
      end

      def attach_image(celebrity)
        if params[:celebrity][:image].present? && params[:celebrity][:image].is_a?(ActionDispatch::Http::UploadedFile)
          celebrity.image.attach(params[:celebrity][:image])
        end
      end

      def ensure_supervisor
        unless @current_user&.supervisor?
          render json: { error: 'Forbidden: Supervisor access required' }, status: :forbidden and return
        end
      end
    end
  end
end