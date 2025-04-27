ActiveAdmin.register Movie do
  permit_params :title, :genre, :release_year, :director, :duration, :description, :premium, :poster, :banner, :main_lead,:rating, :streaming_platform

  index do
    selectable_column
    id_column
    column :title
    column :genre
    column :release_year
    column :director
    column :duration
    column :description
    column :premium
    column :main_lead
    column :streaming_platform
    column :rating
    column :poster do |movie|
      if movie.poster.attached?
        image_tag cl_image_path(movie.poster.key, width: 100, crop: :fill), alt: "Poster"
      else
        "No Poster"
      end
    end
    column :banner do |movie|
      if movie.banner.attached?
        image_tag cl_image_path(movie.banner.key, width: 100, crop: :fill), alt: "Banner"
      else
        "No Banner"
      end
    end
    column :poster_url do |movie|
      movie.poster.attached? ? cloudinary_url(movie.poster.key) : "N/A"
    end
    column :banner_url do |movie|
      movie.banner.attached? ? cloudinary_url(movie.banner.key) : "N/A"
    end
    actions
  end

  filter :title
  filter :genre
  filter :release_year
  filter :director
  filter :duration
  filter :premium
  filter :main_lead
  filter :streaming_platform
  filter :rating

  form do |f|
    f.inputs do
      f.input :title
      f.input :genre
      f.input :release_year
      f.input :director
      f.input :duration
      f.input :description
      f.input :premium
      f.input :main_lead
      f.input :streaming_platform
      f.input :rating
      f.input :poster, as: :file
      f.input :banner, as: :file
    end
    f.actions
  end
end