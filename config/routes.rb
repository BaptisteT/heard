Heard::Application.routes.draw do
 
  namespace :api do
    namespace :v1  do
      resources :messages, only: [:create]
      resources :users, only: [:create]
      resources :sessions, only: [:create]

      put "users/update_token" => "users#update_token"
      get "sessions/confirm_sms_code" => "sessions#confirm_sms_code"
    end
  end
end
