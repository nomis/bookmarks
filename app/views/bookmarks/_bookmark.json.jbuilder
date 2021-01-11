json.extract! bookmark, :id, :title, :uri, :tags_string, :created_at, :updated_at
json.url bookmark_url(bookmark, format: :json)
