class AdminUser < ApplicationRecord
  devise :database_authenticatable, 
          :validatable

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "remember_created_at", "updated_at"]
  end
end
