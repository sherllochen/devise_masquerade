Dummy::Application.routes.draw do
  devise_for :users, :admins

  root :to => 'dashboard#index'
end

