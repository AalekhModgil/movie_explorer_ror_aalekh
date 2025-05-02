class ApplicationController < ActionController::Base
  before_action :set_default_response_format

  protected

  def authenticate_user!
    auth_header = request.headers['Authorization']
    logger.info "Authenticating with header: #{auth_header}"
  
    if auth_header.blank? || !auth_header.start_with?('Bearer ')
      logger.info "No valid Bearer token provided"
      render json: { error: 'No token provided. Please sign in.' }, status: :unauthorized
      return
    end
  
    token = auth_header.split('Bearer ').last
    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
      jti = decoded_token.first['jti']
      user_id = decoded_token.first['sub']
      
      if JwtBlacklist.exists?(jti: jti)
        logger.info "Token is blacklisted"
        render json: { error: 'Token has been revoked. Please sign in again.' }, status: :unauthorized
        return
      end
  
      user = User.find_by(id: user_id)
      if user
        logger.info "Authenticated user: #{user.inspect}"
        @current_user = user
      else
        logger.info "No user found for token"
        render json: { error: 'Invalid token: User not found.' }, status: :unauthorized
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      logger.info "Token decode error: #{e.message}"
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    end
  end

  private

  def set_default_response_format
    request.format = :json if request.path.start_with?('/api')
  end
end