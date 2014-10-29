require 'sidekiq/web'

Heard::Application.routes.draw do
  root :to => "home#index"
  get "/beta" => "home#beta"
  get "/groups" => "home#groups"
  post "/" => "home#text_link"
  get "/privacy" => "home#privacy"
   get "/stats" => "home#stats"

  #Sinatra app to monitor queues provided by sidekiq/web
  mount Sidekiq::Web, at: '/sidekiq'

  namespace :api do
    namespace :v1  do
      resources :messages, only: [:create]
      resources :users, only: [:create]
      resources :sessions, only: [:create]
      resources :blockades, only: [:create]
      resources :groups, only: [:create]

      patch "users/update_push_token" => "users#update_push_token"
      get "sessions/confirm_sms_code" => "sessions#confirm_sms_code"
      get "messages/unread_messages" => "messages#unread_messages"
      get "users/unread_messages" => "messages#unread_messages" #to be removed, for backward compatibility
      patch "messages/mark_as_opened" => "messages#mark_as_opened"
      post "users/get_my_contact" => "users#get_my_contact"
      post "users/get_contacts_and_futures" => "users#get_contacts_and_futures"
      get "users/get_user_info" => "users#get_user_info"
      post "report_crash" => "api#report_crash"
      get "/obsolete_api" => "api#obsolete_api"
      post "create_for_all" => "messages#create_for_all"
      get "admin_messages" => "messages#admin_messages"
      patch "users/update_profile_picture" => "users#update_profile_picture"
      patch "users/update_first_name" => "users#update_first_name"
      patch "users/update_last_name" => "users#update_last_name"
      patch "users/update_micro_auth" => "users#update_micro_auth"
      patch "users/update_address_book_stats" => "users#update_address_book_stats"
      get "users/user_presence" => "users#user_presence"
      get "messages/last_message" => "messages#last_message"
      get "users/active_contacts" => "users#get_user_active_contacts"
      get "messages/retrieve_conversation" => "messages#retrieve_conversation"
      patch "users/update_app_info" => "users#update_app_info"
      post "messages/create_future_messages" => "messages#create_future_messages"
      get "messages/is_recording" => "messages#is_recording"
      post "users/fb_create" => "users#fb_create"
      get "groups/get_group_info" => "groups#get_group_info"
      post "groups/leave_group" => "groups#leave_group"
      post "groups/add_member" => "groups#add_member"
    end
  end
end
