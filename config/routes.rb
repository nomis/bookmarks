# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations", sessions: "sessions" }
  root "bookmarks#index"
  get "/bookmarks/compose", to: "bookmarks#compose", as: :compose_bookmark, constraints: { format: ["html"] }
  get "/bookmarks/incremental", to: "bookmarks#incremental", as: :incremental_bookmark, constraints: { format: ["js"] }
  resources :bookmarks, constraints: { format: ["html", "json", "xml"] }
  get "/bookmarks/:id/delete", to: "bookmarks#delete", as: :delete_bookmark, constraints: { format: ["html"] }
  get "/tags/:tags", to: "bookmarks#search", as: :search_by_tags, constraints: { format: ["html", "json", "xml"] }
end
