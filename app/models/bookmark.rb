class Bookmark < ApplicationRecord
  has_and_belongs_to_many :tags

  validates :title, presence: true, length: { maximum: 255 }
  validates :uri, presence: true, length: { maximum: 4096 }
  validate :validate_tags_string

  before_save :save_tags_string

  def tags_string
    (@tags_string ? @tags_string.values : tags).map{ |tag| tag.name }.sort.join(" ")
  end

  def tags_string=(tags_string)
    @tags_string = tags_string.split.map{ |name| Tag.new(name: name) }.map{ |tag| [tag.key, tag] }.to_h
  end

  private
    MAX_TAGS = 100

    def validate_tags_string
      if @tags_string then
        if @tags_string.size > MAX_TAGS then
          errors.add(:tags_string, "limit reached (maximum is " \
            + ActionController::Base.helpers.pluralize(MAX_TAGS, "tag") + ")")
        end

        @tags_string.values.each do |tag|
          if not tag.valid?
            tag.errors.messages.values.flatten.each do |message|
              errors.add(:tags_string, '"' + tag.name + '" ' + message)
            end
          end
        end
      end
    end

    def save_tags_string
      return if @tags_string.nil?

      new_tags = @tags_string

      with_lock do
        old_keys = tags.map{ |tag| tag.key }

        # Add new tags but don't update the case of the tag name
        (new_tags.keys - old_keys).each do |new_key|
          new_tag = Tag.find_by(key: new_key)
          if new_tag.nil? then
            new_tag = new_tags[new_key]
          end
          tags << new_tag
        end

        removed_tags = []

        tags.each do |old_tag|
          if new_tags.include? old_tag.key
            # Update case for the names of existing tags
            if old_tag.name != new_tags[old_tag.key].name then
              old_tag.name = new_tags[old_tag.key].name
              old_tag.save!
            end
          else
            # Delete removed tags
            removed_tags << old_tag.id
            tags.delete(old_tag)
          end
        end

        # Delete tags that now have no bookmarks
        if not removed_tags.empty? then
          Tag.delete(Tag.where.missing(:bookmarks).where(id: removed_tags))
        end
      end
    end
end
