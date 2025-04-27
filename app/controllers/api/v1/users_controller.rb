module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!
      skip_before_action :verify_authenticity_token, if: :json_request?

      def current
        render json: { id: current_user.id, email: current_user.email, role: current_user.role }
      end

      private

      def json_request?
        request.format.json?
      end
    end
  end
end