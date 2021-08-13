# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations", sessions: "sessions" }

  root "bookmarks#index"

  get "/bookmarks/compose", to: "bookmarks#compose",
    as: :compose_bookmark, constraints: { format: ["html"] }
  get "/bookmarks/compose_with_session", to: "bookmarks#compose_with_session",
    as: :compose_bookmark_with_session, constraints: { format: ["html"] }
  get "/bookmarks/incremental", to: "bookmarks#incremental",
    as: :incremental_bookmark, constraints: { format: ["json"] }
  resources :bookmarks, constraints: { format: ["html", "json", "xml"] }
  get "/bookmarks/:id/delete", to: "bookmarks#delete",
    as: :delete_bookmark, constraints: { format: ["html"] }

  get "/tags/:tags", to: "bookmarks#search_tagged",
    as: :search_by_tags, constraints: { format: ["html", "json", "xml"] }
  get "/untagged", to: "bookmarks#search_untagged",
    as: :search_untagged, constraints: { format: ["html", "json", "xml"] }

  get "/lookup/url", to: "lookup#url",
    as: :lookup_url, constraints: { format: ["json"] }

  get "/about/source", to: "about#source"
end
