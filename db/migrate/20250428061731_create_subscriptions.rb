class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plan_type, null: false
      t.string :status, null: false, default: 'active'

      t.timestamps
    end
  end
end
