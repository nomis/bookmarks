json.extract! bookmark, :id, :title, :uri
json.tags bookmark.tags do |tag|
  json.extract! tag, :id, :name, :created_at, :updated_at
end
json.extract! bookmark, :created_at, :updated_at
