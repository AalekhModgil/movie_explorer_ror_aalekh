class ApplicationController < ActionController::Base
  respond_to :json

  protected

  def authenticate_user!
    unless current_user
      render json: { error: 'You need to sign in first.' }, status: :unauthorized
    else
      super
    end
  end
end