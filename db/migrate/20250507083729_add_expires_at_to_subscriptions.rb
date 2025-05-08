class AddExpiresAtToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :expires_at, :datetime
    add_index :subscriptions, :expires_at
  end
end
