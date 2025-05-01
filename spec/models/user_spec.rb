require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }
  let(:invalid_user) { build(:user, :invalid) }

  # Test validations
  describe "validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    it "is not valid without a name" do
      user.name = nil
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "is not valid if name is too short" do
      user.name = "ab"
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("is too short (minimum is 3 characters)")
    end

    it "is not valid if name is too long" do
      user.name = "a" * 101
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("is too long (maximum is 100 characters)")
    end

    it "is not valid without a mobile number" do
      user.mobile_number = nil
      expect(user).not_to be_valid
      expect(user.errors[:mobile_number]).to include("can't be blank")
    end

    it "is not valid with an invalid mobile number format" do
      user.mobile_number = "123"
      expect(user).not_to be_valid
      expect(user.errors[:mobile_number]).to include("is invalid")
    end

    it "is not valid with a duplicate mobile number" do
      create(:user, mobile_number: "+1234567890")
      duplicate_user = build(:user, mobile_number: "+1234567890")
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:mobile_number]).to include("has already been taken")
    end

    it "is not valid without an email" do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "is not valid with an invalid email format" do
      user.email = "invalid-email"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "is not valid with a duplicate email" do
      create(:user, email: "john@example.com")
      duplicate_user = build(:user, email: "john@example.com")
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include("has already been taken")
    end

    it "is not valid without a password" do
      user.password = nil
      user.password_confirmation = nil
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "is not valid with invalid attributes" do
      expect(invalid_user).not_to be_valid
      expect(invalid_user.errors[:email]).to include("is invalid")
      expect(invalid_user.errors[:password]).to include("can't be blank")
      expect(invalid_user.errors[:name]).to include("can't be blank", "is too short (minimum is 3 characters)")
      expect(invalid_user.errors[:mobile_number]).to include("can't be blank", "is invalid")
    end
  end

  # Test Devise/JWT-related functionality
  describe "Devise and JWT functionality" do
    it "is valid with a unique jti" do
      user = create(:user)
      expect(user.jti).to be_present
    end

    it "includes role in JWT payload" do
      user = create(:user, role: :supervisor)
      payload = user.jwt_payload
      expect(payload).to eq('role' => 'supervisor')
    end
  end

  # Test enum
  describe "role enum" do
    it "defines user and supervisor roles" do
      expect(User.roles).to eq("user" => 0, "supervisor" => 1)
    end
  
    it "sets default role to user" do
      user = create(:user)
      expect(user.role).to eq("user")
    end
  
    it "allows role to be supervisor" do
      user = create(:user, :supervisor)
      expect(user.role).to eq("supervisor")
    end
  end

  # Test scopes
  describe "scopes" do
    it "filters users by role" do
      user1 = create(:user, role: :user)
      user2 = create(:user, role: :supervisor)
      expect(User.by_role(:supervisor)).to include(user2)
      expect(User.by_role(:supervisor)).not_to include(user1)
    end

    it "orders users by recent creation" do
      older_user = create(:user, created_at: 2.days.ago)
      newer_user = create(:user, created_at: 1.day.ago)
      expect(User.recent.first).to eq(newer_user)
      expect(User.recent.last).to eq(older_user)
    end
  end
end