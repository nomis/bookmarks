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

  get "/public", to: "bookmarks#index",
    as: :search_public, constraints: {
      format: ["html", "json", "xml"],
    }, defaults: { visibility: "public" }
  get "/private", to: "bookmarks#index",
    as: :search_private, constraints: {
      format: ["html", "json", "xml"],
    }, defaults: { visibility: "private" }

  get "(/:visibility)/tags/:tags", to: "bookmarks#index",
    as: :search_by_tags, constraints: {
      format: ["html", "json", "xml"],
      visibility: ["public", "private"]
    }
  get "(/:visibility)/untagged", to: "bookmarks#index",
    as: :search_untagged, constraints: {
      format: ["html", "json", "xml"],
      visibility: ["public", "private"]
    }, defaults: { untagged: true }

  get "/lookup/url", to: "lookup#url",
    as: :lookup_url, constraints: { format: ["json"] }

  get "/about/source", to: "about#source"
end
