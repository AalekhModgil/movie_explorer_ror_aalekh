class RemoveColumnsFromAdmin < ActiveRecord::Migration[7.1]
  def change
    remove_column :admin_users, :reset_password_token
    remove_column :admin_users, :reset_password_sent_at
    remove_column :admin_users, :remember_created_at
  end
end
