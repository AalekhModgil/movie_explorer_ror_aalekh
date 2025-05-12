require 'rails_helper'

RSpec.describe Subscription, type: :model do
  let(:subscription) { build(:subscription) }
  let(:invalid_subscription) { build(:subscription, :invalid) }

  describe 'associations' do
    it 'belongs to a user' do
      expect(Subscription.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(subscription).to be_valid
    end

    it 'is not valid without a plan_type' do
      subscription.plan_type = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:plan_type]).to include('is not included in the list')
    end

    it 'is not valid with an invalid plan_type' do
      subscription.plan_type = 'invalid_plan'
      expect(subscription).not_to be_valid
      expect(subscription.errors[:plan_type]).to include('is not included in the list')
    end

    it 'is valid with a basic plan_type' do
      subscription.plan_type = 'basic'
      expect(subscription).to be_valid
    end

    it 'is valid with a premium plan_type' do
      subscription.plan_type = 'premium'
      expect(subscription).to be_valid
    end

    it 'is not valid without a status' do
      subscription.status = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:status]).to include('is not included in the list')
    end

    it 'is not valid with an invalid status' do
      subscription.status = 'invalid_status'
      expect(subscription).not_to be_valid
      expect(subscription.errors[:status]).to include('is not included in the list')
    end

    it 'is valid with an active status' do
      subscription.status = 'active'
      expect(subscription).to be_valid
    end

    it 'is valid with an inactive status' do
      subscription.status = 'inactive'
      expect(subscription).to be_valid
    end

    it 'is valid with a cancelled status' do
      subscription.status = 'cancelled'
      expect(subscription).to be_valid
    end

    it 'is not valid with invalid attributes' do
      expect(invalid_subscription).not_to be_valid
      expect(invalid_subscription.errors[:plan_type]).to include('is not included in the list')
      expect(invalid_subscription.errors[:status]).to include('is not included in the list')
    end
  end

  describe 'helper methods' do
    context 'basic? method' do
      it 'returns true for a basic plan' do
        subscription = build(:subscription, :basic)
        expect(subscription.basic?).to be true
        expect(subscription.premium?).to be false
      end

      it 'returns false for a premium plan' do
        subscription = build(:subscription, :premium)
        expect(subscription.basic?).to be false
        expect(subscription.premium?).to be true
      end
    end

    context 'premium? method' do
      it 'returns true for a premium plan' do
        subscription = build(:subscription, :premium)
        expect(subscription.premium?).to be true
        expect(subscription.basic?).to be false
      end

      it 'returns false for a basic plan' do
        subscription = build(:subscription, :basic)
        expect(subscription.premium?).to be false
        expect(subscription.basic?).to be true
      end
    end
  end
end