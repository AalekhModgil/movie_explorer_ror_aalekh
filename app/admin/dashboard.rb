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

      column do
        panel "Movie Statistics" do
          ul do
            li "Total Movies: #{Movie.count}"
            li "Premium Movies: #{Movie.where(premium: true).count}"
            li "Non-Premium Movies: #{Movie.where(premium: false).count}"
            li "Average Rating: #{Movie.average(:rating)&.round(2) || 'N/A'}"
            li "Movies by Genre: #{Movie.group(:genre).count.to_h.to_s}"
            li "Recent Movies: #{Movie.order(release_year: :desc).limit(5).pluck(:title).join(', ')}"
            li "Streaming Platforms: #{Movie.group(:streaming_platform).count.to_h.to_s}"
          end
        end
      end
    end
  end
end