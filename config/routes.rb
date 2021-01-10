Rails.application.routes.draw do
  root "bookmarks#index"
  resources :bookmarks
end
