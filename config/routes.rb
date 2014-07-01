Heard::Application.routes.draw do
  root :to => "home#index"
  get "/beta" => "home#beta"

  namespace :api do
    namespace :v1  do
      resources :messages, only: [:create]
      resources :users, only: [:create]
      resources :sessions, only: [:create]
      resources :blockades, only: [:create]

      patch "users/update_push_token" => "users#update_push_token"
      get "sessions/confirm_sms_code" => "sessions#confirm_sms_code"
      get "messages/unread_messages" => "messages#unread_messages"
      patch "messages/mark_as_opened" => "messages#mark_as_opened"
      post "users/get_my_contact" => "users#get_my_contact"
      get "users/get_user_info" => "users#get_user_info"
    end
  end
end
