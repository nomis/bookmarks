# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

json.extract! bookmark, :id, :title, :uri
json.tags bookmark.tags do |tag|
  json.extract! tag, :id, :name, :created_at, :updated_at
end
json.extract! bookmark, :created_at, :updated_at
