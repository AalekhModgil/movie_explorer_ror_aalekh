class JwtBlacklist < ApplicationRecord
  self.table_name = 'jwt_blacklists'

  def self.revoked?(payload)
    find_by(jti: payload['jti']).present?
  end

  def self.revoke(payload)
    create(jti: payload['jti'], exp: Time.at(payload['exp']))
  end
end