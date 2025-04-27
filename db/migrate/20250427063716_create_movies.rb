class CreateMovies < ActiveRecord::Migration[7.1]
  def change
    create_table :movies do |t|
      t.string :title
      t.string :genre
      t.integer :release_year
      t.float :rating
      t.string :director
      t.integer :duration
      t.string :streaming_platform
      t.string :main_lead
      t.text :description
      t.boolean :premium, default: false

      t.timestamps
    end
  end
end
