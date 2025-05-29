class AddRoleToCelebrities < ActiveRecord::Migration[7.1]
  def change
    add_column :celebrities, :role, :string, null: false, default: "actor"
  end
end
