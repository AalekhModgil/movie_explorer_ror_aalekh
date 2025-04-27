ActiveAdmin.register User do
  permit_params :name, :email, :password, :password_confirmation, :mobile_number, :role

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :mobile_number
    column :role
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :mobile_number
      f.input :role, as: :select, collection: User.roles.keys
    end
    f.actions
  end

  filter :email
  filter :role, as: :select, collection: User.roles.keys
end