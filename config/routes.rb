Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }
  namespace :api do
    namespace :v1 do
      resources :movies, only: [:index, :show, :create, :update, :destroy]
      get 'current_user', to: 'users#current'
      resources :subscriptions, only: [:create] do
        collection do
          get 'success'
          get 'cancel'
        end
      end
      post 'webhooks/stripe', to: 'webhooks#stripe'
    end
  end
end