require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  setup do
    @one = bookmarks(:one)
    @two = bookmarks(:two)
  end

  test "add new tags" do
    @one.tags_string = "Test some tags"
    assert @one.save

    assert_equal("some tags Test", Bookmark.find(@one.id).tags_string)
  end

  test "add existing tags" do
    @one.tags_string = "Test some tags"
    assert @one.save

    assert_equal("some tags Test", Bookmark.find(@one.id).tags_string)

    # Adding an existing tag to a bookmark reuses the case that was there before
    @two.tags_string = "test Some Tags"
    assert @two.save

    assert_equal("some tags Test", Bookmark.find(@one.id).tags_string)
    assert_equal("some tags Test", Bookmark.find(@two.id).tags_string)
  end

  test "update existing tags" do
    @one.tags_string = "Test some tags"
    assert @one.save

    assert_equal("some tags Test", Bookmark.find(@one.id).tags_string)

    @two.tags_string = "test Some Tags"
    assert @two.save

    assert_equal("some tags Test", Bookmark.find(@two.id).tags_string)

    # Change the case of the "test" tag that is already present and remove the
    # other tags
    @two.tags_string = "TEST"
    assert @two.save

    assert_equal("some tags TEST", Bookmark.find(@one.id).tags_string)
    assert_equal("TEST", Bookmark.find(@two.id).tags_string)
  end

  test "add deleted tag" do
    @one.tags_string = "Test some tags"
    assert @one.save

    assert_equal("some tags Test", Bookmark.find(@one.id).tags_string)

    # Remove the "Test" tag, which is now unused so it will be deleted
    @one.tags_string = "some tags"
    assert @one.save

    assert_equal("some tags", Bookmark.find(@one.id).tags_string)

    # Add the "TEST" tag, which is now new again so it will have this case
    @two.tags_string = "TEST SOME TAGS"
    assert @two.save

    assert_equal("some tags", Bookmark.find(@one.id).tags_string)
    assert_equal("some tags TEST", Bookmark.find(@two.id).tags_string)
  end
end
