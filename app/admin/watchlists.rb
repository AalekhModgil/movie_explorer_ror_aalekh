ActiveAdmin.register Watchlist do
  permit_params :user_id, :movie_id

  index do
    selectable_column
    id_column
    column :user
    column :movie
    column :created_at
    column :updated_at
    actions
  end

  filter :user
  filter :movie
  filter :created_at

  form do |f|
    f.inputs do
      f.input :user
      f.input :movie
    end
    f.actions
  end
end