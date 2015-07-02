Rails.application.routes.draw do
  get 'login' => 'user_session#new'

  post 'login' => 'user_session#create'

  get 'logout' => 'user_session#destroy', :as => 'log_out'

  get 'delete' => 'users#destroy', :as => 'delete'

  resources :users 

  resources :messages

  resources :inbox

  root 'user_session#login'

end
