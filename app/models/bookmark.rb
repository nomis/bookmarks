class Bookmark < ApplicationRecord
  validates :title, presence: true, length: { maximum: 4096 }
  validates :uri, presence: true, length: { maximum: 4096 }
end
