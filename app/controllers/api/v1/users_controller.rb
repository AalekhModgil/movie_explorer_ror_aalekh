module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!
      skip_before_action :verify_authenticity_token
      
      def current
        if @current_user
          render json: {
            id: @current_user.id,
            name: @current_user.name,
            email: @current_user.email,
            mobile_number: @current_user.mobile_number,
            role: @current_user.role
          }, status: :ok
        else
          render json: { error: 'No user signed in' }, status: :unauthorized
        end
      end

      def update_device_token
        if @current_user.update(device_token: device_token_params[:device_token])
          render json: { message: "Device token updated successfully" }, status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def toggle_notifications
        new_status = params[:notifications_enabled] == "true" || params[:notifications_enabled] == true
        if @current_user.update(notifications_enabled: new_status)
          render json: { message: "Notification preference updated", notifications_enabled: @current_user.notifications_enabled }, status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def json_request?
        request.format.json?
      end

      def device_token_params
        params.permit(:device_token)
      end
    end
  end
end