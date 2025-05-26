class CreateCelebrities < ActiveRecord::Migration[7.1]
  def change
    create_table :celebrities do |t|
      t.string :name, null: false
      t.date :birth_date, null: false
      t.string :nationality, null: false
      t.text :biography, null: false
      t.timestamps
    end
  end
end
