class Bookmark < ApplicationRecord
  has_and_belongs_to_many :tags

  validates :title, presence: true, length: { maximum: 255 }
  validates :uri, presence: true, length: { maximum: 4096 }
  validate :validate_tags_string

  after_save :save_tags_string
  before_destroy :remove_all_tags

  def tags_string
    (@new_tags ? @new_tags.values : tags).map{ |tag| tag.name }.sort.join(" ")
  end

  def tags_string=(tags_string)
    @new_tags = tags_string.split.map{ |name| Tag.new(name: name) }.map{ |tag| [tag.key, tag] }.to_h
  end

  private
    MAX_TAGS = 100

    def validate_tags_string
      if @new_tags then
        if @new_tags.size > MAX_TAGS then
          errors.add(:tags_string, "limit reached (maximum is " \
            + ActionController::Base.helpers.pluralize(MAX_TAGS, "tag") + ")")
        end

        @new_tags.values.each do |tag|
          if not tag.valid?
            tag.errors.messages.values.flatten.each do |message|
              errors.add(:tags_string, '"' + tag.name + '" ' + message)
            end
          end
        end
      end
    end

    def save_tags_string
      return if @new_tags.nil?

      old_keys = tags.map{ |tag| tag.key }

      # Add new tags but don't update the case of the tag name
      (@new_tags.keys - old_keys).each do |new_key|
        # Concurrency issue: the same tag may be created in another thread
        # (there is no way to resolve this here because we'd need a second
        # independent transaction and that could leave unreferenced tags if an
        # error occurs)
        new_tag = Tag.find_by(key: new_key)
        if new_tag.nil? then
          new_tag = @new_tags[new_key]
        end
        tags << new_tag
      end

      removed_tags = []

      tags.each do |old_tag|
        if @new_tags.include? old_tag.key
          # Update case for the names of existing tags
          if old_tag.name != @new_tags[old_tag.key].name then
            old_tag.name = @new_tags[old_tag.key].name
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
        # Concurrency issue: the last two users of the tag may remove it in
        # two separate threads but neither of them can identify this within
        # their own transaction, leaving the tag unreferenced
        #
        # Potential concurrency issue: the tag may be reused in another thread
        # (databases may handle conflicts with this DELETE in different ways
        # so it could silently ignore newly referenced tags or raise an error
        # on the foreign key constraint)
        Tag.where.missing(:bookmarks).where(id: removed_tags).delete_all
      end

      @new_tags = nil
    end

    def remove_all_tags
      @new_tags = {}
      save_tags_string
    end
end
