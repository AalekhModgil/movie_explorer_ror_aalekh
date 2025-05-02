class Users::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :verify_authenticity_token
  skip_before_action :require_no_authentication, only: [:create]
  skip_before_action :verify_signed_out_user, only: [:destroy]

  def create
    warden.logout if warden.authenticated?(:user)
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with(resource, _opts = {})
  end

  def destroy
    auth_header = request.headers['Authorization']
    logger.info "Sign-out request with auth header: #{auth_header}"

    if auth_header.blank? || !auth_header.start_with?('Bearer ')
      logger.info "No valid Bearer token provided"
      render json: { error: "No token provided. Please include a valid Bearer token." }, status: :unauthorized
      return
    end

    token = auth_header.split('Bearer ').last
    logger.info "Processing token: #{token}"
    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
      user_id = decoded_token.first['sub']
      jti = decoded_token.first['jti']
      user = User.find_by(id: user_id)

      if user
        if ::JwtBlacklist.revoked?(decoded_token.first)
          logger.info "Token already revoked: jti #{jti}"
          render json: { error: "Token already revoked." }, status: :unauthorized
          return
        end

        logger.info "Revoking token for user ID: #{user_id}, jti: #{jti}"
        ::JwtBlacklist.revoke(decoded_token.first)
        warden.logout
        response.delete_header('Authorization') 
        render json: { message: "Signed out successfully." }, status: :ok
      else
        logger.info "No user found for token"
        render json: { error: "Invalid token: User not found." }, status: :unauthorized
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      logger.info "Token decode error: #{e.message}"
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    end
  end
  
  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        id: resource.id,
        email: resource.email,
        role: resource.role,
        token: request.env['warden-jwt_auth.token']
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end
end