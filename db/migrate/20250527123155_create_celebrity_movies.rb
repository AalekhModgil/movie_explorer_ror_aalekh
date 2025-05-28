class CreateCelebrityMovies < ActiveRecord::Migration[7.1]
  def change
    create_table :celebrity_movies do |t|
      t.bigint :celebrity_id, null: false
      t.bigint :movie_id, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [:celebrity_id, :movie_id], unique: true
      t.index :movie_id
    end

    add_foreign_key :celebrity_movies, :celebrities
    add_foreign_key :celebrity_movies, :movies
  end
end
