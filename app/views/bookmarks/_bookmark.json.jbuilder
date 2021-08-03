# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

json.extract! bookmark, :id, :title, :uri
json.tags bookmark.tags do |tag|
  json.extract! tag, :id, :name, :created_at, :updated_at
end
if user_signed_in?
  json.extract! bookmark, :private
end
json.extract! bookmark, :created_at, :updated_at
