Heard::Application.routes.draw do
 
  namespace :api do
    namespace :v1  do
      resources :messages, only: [:create]
      resources :users, only: [:create]
      resources :sessions, only: [:create]

      patch "users/update_push_token" => "users#update_push_token"
      get "sessions/confirm_sms_code" => "sessions#confirm_sms_code"
      get "users/unread_messages" => "users#unread_messages"
      patch "messages/mark_as_opened" => "messages#mark_as_opened"
    end
  end
end
