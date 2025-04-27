# app/admin/dashboard.rb
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      # User Statistics
      column do
        panel "User Statistics" do
          ul do
            li "Total Users: #{User.count}"
            li "Regular Users: #{User.where(role: 'user').count}"
            li "Supervisors: #{User.where(role: 'supervisor').count}"
          end
        end
      end

      # Admin Statistics
      column do
        panel "Admin Statistics" do
          ul do
            li "Total Admins: #{AdminUser.count}"
          end
        end
      end
    end
  end
end