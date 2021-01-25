# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

Rails.application.routes.draw do
  root "bookmarks#index"
  resources :bookmarks, constraints: { format: ["html", "json"] }
  get '/tags/:tags', to: 'bookmarks#search', as: :search_by_tags, constraints: { format: ["html", "json"] }
  get "/tags/:tags", to: "bookmarks#search", as: :search_by_tags, constraints: { format: ["html", "json"] }
end
