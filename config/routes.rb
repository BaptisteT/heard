Heard::Application.routes.draw do
 
  namespace :api do
    namespace :v1  do
      resources :messages, only: [:create]
    end
  end
end
