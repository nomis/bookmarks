Rails.application.routes.draw do
  root "bookmarks#index"
  resources :bookmarks, constraints: { format: ["html", "json"] }
end
