require 'sidekiq/web'

Heard::Application.routes.draw do
  root :to => "home#index"
  get "/beta" => "home#beta"

  #Sinatra app to monitor queues provided by sidekiq/web
  mount Sidekiq::Web, at: '/sidekiq'

  namespace :api do
    namespace :v1  do
      resources :messages, only: [:create]
      resources :users, only: [:create]
      resources :sessions, only: [:create]
      resources :blockades, only: [:create]

      patch "users/update_push_token" => "users#update_push_token"
      get "sessions/confirm_sms_code" => "sessions#confirm_sms_code"
      get "messages/unread_messages" => "messages#unread_messages"
      get "users/unread_messages" => "messages#unread_messages" #to be removed, for backward compatibility
      patch "messages/mark_as_opened" => "messages#mark_as_opened"
      post "users/get_my_contact" => "users#get_my_contact"
      get "users/get_user_info" => "users#get_user_info"
      post "report_crash" => "api#report_crash"
      get "/obsolete_api" => "api#obsolete_api"
      post "create_for_all" => "messages#create_for_all"
      get "admin_messages" => "messages#admin_messages"
      patch "users/update_profile_picture" => "users#update_profile_picture"
      patch "users/update_first_name" => "users#update_first_name"
      patch "users/update_last_name" => "users#update_last_name"
    end
  end
end
