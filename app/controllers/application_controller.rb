class ApplicationController < ActionController::Base
  before_action :set_default_response_format

  protected

  def authenticate_user!
    unless current_user
      render json: { error: 'You need to sign in first.' }, status: :unauthorized
    else
      super
    end
  end

  private

  def set_default_response_format
    request.format = :json if request.path.start_with?('/api')
  end
end