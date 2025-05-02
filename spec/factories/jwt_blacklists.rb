FactoryBot.define do
  factory :jwt_blacklist do
    jti { "MyString" }
    exp { "2025-05-02 12:28:11" }
  end
end
