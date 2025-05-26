ActiveAdmin.register Celebrity do
  permit_params :name, :birth_date, :nationality, :biography, :image

  form do |f|
    f.inputs do
      f.input :name
      f.input :birth_date, as: :date_picker
      f.input :nationality
      f.input :biography
      f.input :image, as: :file
    end
    f.actions
  end

  index do
    selectable_column
    id_column
    column :name
    column :birth_date
    column :age do |celebrity|
      celebrity.age
    end
    column :nationality
    column :biography
    column :image do |celebrity|
      image_tag celebrity.image.url, size: '50x50' if celebrity.image.attached?
    end
    actions
  end

  filter :name
  filter :nationality
  filter :birth_date
  filter :biography

  show do
    attributes_table do
      row :name
      row :birth_date
      row :age do |celebrity|
        celebrity.age
      end
      row :nationality
      row :biography
      row :image do |celebrity|
        image_tag celebrity.image.url if celebrity.image.attached?
      end
    end
  end
end