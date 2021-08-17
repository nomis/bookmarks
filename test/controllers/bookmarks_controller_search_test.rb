require "test_helper"

class BookmarksControllerSearchTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # Fewer items per page so that there are more pages
    Pagy::VARS[:items] = 10

    sign_in users(:one)

    Bookmark.destroy_all
    Tag.destroy_all

    n = 0
    ["", "A", "B", "C", "A B", "B C"].each do |tags|
      [true, false].each do |private|
        (1..25).each do |i|
          b = Bookmark.create(
            title: "Test #{tags} #{private ? "private" : "public"} #{i}",
            uri: "https://#{n}.test/")
          b.tags_string = tags
          b.private = private
          b.save!

          n += 1
        end
      end
    end

    @a = Tag.find_by(name: "A")
    @b = Tag.find_by(name: "B")
    @c = Tag.find_by(name: "C")
  end

  def tag_links
    css_select("ul.main.tags li a").map do |link|
      [link["href"], link.text, link["title"]]
    end
  end

  def next_incremental
    css_select("#more_link")[0]["data-href"]
  end

  def next_incremental_json
    Nokogiri::HTML(@response.parsed_body["pagination"]).css("#more_link")[0]["data-href"]
  end

  def query(others = {})
    @query.merge(others)
  end

  def incremental_query(others = {})
    @incremental_query.merge(others)
  end

  def list_bookmarks(path, args = {}, incremental_args = {})
    @path = path
    @query = args
    @incremental_query = {format: "json"}
      .merge(incremental_args)
      .merge(@query.map { |key, value| ["search_#{key}", value] }.to_h)

    get @path.call(query)
    assert_response :success
  end

  def verify_pagination
    # Check that page 2 exists
    assert_select "a[rel=next][href=?]", @path.call(query(page: 2)), text: "2"

    # Check that incremental href is page 2
    assert_equal incremental_bookmark_path(incremental_query(page: 2)), next_incremental

    get next_incremental
    assert_response :success

    # Check that incremental href is now page 3
    assert_equal incremental_bookmark_path(incremental_query(page: 3)), next_incremental_json
  end

  test "all bookmarks" do
    list_bookmarks method(:root_path)

    assert_select "title", text: "Bookmarks"
    assert_select "h1", text: "All bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (300)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id}", visibility: nil), "A (100)", 'Search by tag "A"'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "B (150)", 'Search by tag "B"'],
      [search_by_tags_path(tags: "#{@c.id}", visibility: nil), "C (100)", 'Search by tag "C"'],
      [search_untagged_path(visibility: nil), "∅ (50)", "Untagged bookmarks"],
      [search_public_path, "🔓 (150)", "Public bookmarks only"],
      [search_private_path, "🔒 (150)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "public bookmarks" do
    list_bookmarks method(:search_public_path), {}, {search_visibility: "public"}

    assert_select "title", text: "Bookmarks: Public bookmarks"
    assert_select "h1", text: "Public bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (150)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id}", visibility: "public"), "A (50)", 'Search by tag "A"'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: "public"), "B (75)", 'Search by tag "B"'],
      [search_by_tags_path(tags: "#{@c.id}", visibility: "public"), "C (50)", 'Search by tag "C"'],
      [search_untagged_path(visibility: "public"), "∅ (25)", "Untagged bookmarks"],
      [root_path, "🔓 (150)", "All bookmarks"],
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "private bookmarks" do
    list_bookmarks method(:search_private_path), {}, {search_visibility: "private"}

    assert_select "title", text: "Bookmarks: Private bookmarks"
    assert_select "h1", text: "Private bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (150)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id}", visibility: "private"), "A (50)", 'Search by tag "A"'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: "private"), "B (75)", 'Search by tag "B"'],
      [search_by_tags_path(tags: "#{@c.id}", visibility: "private"), "C (50)", 'Search by tag "C"'],
      [search_untagged_path(visibility: "private"), "∅ (25)", "Untagged bookmarks"],
      # Public not available
      [root_path, "🔒 (150)", "All bookmarks"],
    ], tag_links

    verify_pagination
  end

  test "bookmarks with tag A" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@a.id}", visibility: nil}

    assert_select "title", text: "Bookmarks: Search by 1 tag: A"
    assert_select "h1", text: "Search bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (100)"

    assert_equal [
      [root_path, "A (100)", "All bookmarks"],
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: nil), "B (50)", 'Add tag "B" to search'],
      # Uncommon tag "C" not available
      # Untagged not available
      [search_by_tags_path(tags: "#{@a.id}", visibility: "public"), "🔓 (50)", "Public bookmarks only"],
      [search_by_tags_path(tags: "#{@a.id}", visibility: "private"), "🔒 (50)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "public bookmarks with tag A" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@a.id}", visibility: "public"}

    assert_select "title", text: "Bookmarks: Search by 1 tag: A (public bookmarks only)"
    assert_select "h1", text: "Search public bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (50)"

    assert_equal [
      [search_public_path, "A (50)", "All public bookmarks"],
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: "public"), "B (25)", 'Add tag "B" to search'],
      # Uncommon tag "C" not available
      # Untagged not available
      [search_by_tags_path(tags: "#{@a.id}", visibility: nil), "🔓 (50)", "Include private bookmarks"],
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "private bookmarks with tag A" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@a.id}", visibility: "private"}

    assert_select "title", text: "Bookmarks: Search by 1 tag: A (private bookmarks only)"
    assert_select "h1", text: "Search private bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (50)"

    assert_equal [
      [search_private_path, "A (50)", "All private bookmarks"],
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: "private"), "B (25)", 'Add tag "B" to search'],
      # Uncommon tag "C" not available
      # Untagged not available
      # Public not available
      [search_by_tags_path(tags: "#{@a.id}", visibility: nil), "🔒 (50)", "Include public bookmarks"],
    ], tag_links

    verify_pagination
  end

  test "bookmarks with tag A and B" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@a.id},#{@b.id}", visibility: nil}

    assert_select "title", text: "Bookmarks: Search by 2 tags: A, B"
    assert_select "h1", text: "Search bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (50)"

    assert_equal [
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "A (50)", 'Remove tag "A" from search'],
      [search_by_tags_path(tags: "#{@a.id}", visibility: nil), "B (50)", 'Remove tag "B" from search'],
      # Uncommon tag "C" not available
      # Untagged not available
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: "public"), "🔓 (25)", "Public bookmarks only"],
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: "private"), "🔒 (25)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "public bookmarks with tag A and B" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@a.id},#{@b.id}", visibility: "public"}

    assert_select "title", text: "Bookmarks: Search by 2 tags: A, B (public bookmarks only)"
    assert_select "h1", text: "Search public bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (25)"

    assert_equal [
      [search_by_tags_path(tags: "#{@b.id}", visibility: "public"), "A (25)", 'Remove tag "A" from search'],
      [search_by_tags_path(tags: "#{@a.id}", visibility: "public"), "B (25)", 'Remove tag "B" from search'],
      # Uncommon tag "C" not available
      # Untagged not available
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: nil), "🔓 (25)", "Include private bookmarks"],
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "private bookmarks with tag A and B" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@a.id},#{@b.id}", visibility: "private"}

    assert_select "title", text: "Bookmarks: Search by 2 tags: A, B (private bookmarks only)"
    assert_select "h1", text: "Search private bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (25)"

    assert_equal [
      [search_by_tags_path(tags: "#{@b.id}", visibility: "private"), "A (25)", 'Remove tag "A" from search'],
      [search_by_tags_path(tags: "#{@a.id}", visibility: "private"), "B (25)", 'Remove tag "B" from search'],
      # Uncommon tag "C" not available
      # Untagged not available
      # Public not available
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: nil), "🔒 (25)", "Include public bookmarks"],
    ], tag_links

    verify_pagination
  end

  test "bookmarks with tag B" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@b.id}", visibility: nil}

    assert_select "title", text: "Bookmarks: Search by 1 tag: B"
    assert_select "h1", text: "Search bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (150)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: nil), "A (50)", 'Add tag "A" to search'],
      [root_path, "B (150)", "All bookmarks"],
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: nil), "C (50)", 'Add tag "C" to search'],
      # Untagged not available
      [search_by_tags_path(tags: "#{@b.id}", visibility: "public"), "🔓 (75)", "Public bookmarks only"],
      [search_by_tags_path(tags: "#{@b.id}", visibility: "private"), "🔒 (75)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "public bookmarks with tag B" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@b.id}", visibility: "public"}

    assert_select "title", text: "Bookmarks: Search by 1 tag: B (public bookmarks only)"
    assert_select "h1", text: "Search public bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (75)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: "public"), "A (25)", 'Add tag "A" to search'],
      [search_public_path, "B (75)", "All public bookmarks"],
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: "public"), "C (25)", 'Add tag "C" to search'],
      # Untagged not available
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "🔓 (75)", "Include private bookmarks"],
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "private bookmarks with tag B" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@b.id}", visibility: "private"}

    assert_select "title", text: "Bookmarks: Search by 1 tag: B (private bookmarks only)"
    assert_select "h1", text: "Search private bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (75)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id},#{@b.id}", visibility: "private"), "A (25)", 'Add tag "A" to search'],
      [search_private_path, "B (75)", "All private bookmarks"],
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: "private"), "C (25)", 'Add tag "C" to search'],
      # Untagged not available
      # Public not available
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "🔒 (75)", "Include public bookmarks"],
    ], tag_links

    verify_pagination
  end

  test "bookmarks with tag B and C" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@b.id},#{@c.id}", visibility: nil}

    assert_select "title", text: "Bookmarks: Search by 2 tags: B, C"
    assert_select "h1", text: "Search bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (50)"

    assert_equal [
      # Uncommon tag "A" not available
      [search_by_tags_path(tags: "#{@c.id}", visibility: nil), "B (50)", 'Remove tag "B" from search'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "C (50)", 'Remove tag "C" from search'],
      # Untagged not available
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: "public"), "🔓 (25)", "Public bookmarks only"],
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: "private"), "🔒 (25)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "public bookmarks with tag B and C" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@b.id},#{@c.id}", visibility: "public"}

    assert_select "title", text: "Bookmarks: Search by 2 tags: B, C (public bookmarks only)"
    assert_select "h1", text: "Search public bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (25)"

    assert_equal [
      # Uncommon tag "A" not available
      [search_by_tags_path(tags: "#{@c.id}", visibility: "public"), "B (25)", 'Remove tag "B" from search'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: "public"), "C (25)", 'Remove tag "C" from search'],
      # Untagged not available
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: nil), "🔓 (25)", "Include private bookmarks"],
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "private bookmarks with tag B and C" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@b.id},#{@c.id}", visibility: "private"}

    assert_select "title", text: "Bookmarks: Search by 2 tags: B, C (private bookmarks only)"
    assert_select "h1", text: "Search private bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (25)"

    assert_equal [
      # Uncommon tag "A" not available
      [search_by_tags_path(tags: "#{@c.id}", visibility: "private"), "B (25)", 'Remove tag "B" from search'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: "private"), "C (25)", 'Remove tag "C" from search'],
      # Untagged not available
      # Public not available
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: nil), "🔒 (25)", "Include public bookmarks"],
    ], tag_links

    verify_pagination
  end

  test "bookmarks with tag C" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@c.id}", visibility: nil}

    assert_select "title", text: "Bookmarks: Search by 1 tag: C"
    assert_select "h1", text: "Search bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (100)"

    assert_equal [
      # Uncommon tag "A" not available
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: nil), "B (50)", 'Add tag "B" to search'],
      [root_path, "C (100)", "All bookmarks"],
      # Untagged not available
      [search_by_tags_path(tags: "#{@c.id}", visibility: "public"), "🔓 (50)", "Public bookmarks only"],
      [search_by_tags_path(tags: "#{@c.id}", visibility: "private"), "🔒 (50)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "public bookmarks with tag C" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@c.id}", visibility: "public"}

    assert_select "title", text: "Bookmarks: Search by 1 tag: C (public bookmarks only)"
    assert_select "h1", text: "Search public bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (50)"

    assert_equal [
      # Uncommon tag "A" not available
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: "public"), "B (25)", 'Add tag "B" to search'],
      [search_public_path, "C (50)", "All public bookmarks"],
      # Untagged not available
      [search_by_tags_path(tags: "#{@c.id}", visibility: nil), "🔓 (50)", "Include private bookmarks"],
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "private bookmarks with tag C" do
    list_bookmarks method(:search_by_tags_path), {tags: "#{@c.id}", visibility: "private"}

    assert_select "title", text: "Bookmarks: Search by 1 tag: C (private bookmarks only)"
    assert_select "h1", text: "Search private bookmarks"
    assert_select "h2", text: "Tags (2)"
    assert_select "h2", text: "Bookmarks (50)"

    assert_equal [
      # Uncommon tag "A" not available
      [search_by_tags_path(tags: "#{@b.id},#{@c.id}", visibility: "private"), "B (25)", 'Add tag "B" to search'],
      [search_private_path, "C (50)", "All private bookmarks"],
      # Untagged not available
      # Public not available
      [search_by_tags_path(tags: "#{@c.id}", visibility: nil), "🔒 (50)", "Include public bookmarks"],
    ], tag_links

    verify_pagination
  end

  test "untagged bookmarks" do
    list_bookmarks method(:search_untagged_path), {visibility: nil}, {search_untagged: 1}

    assert_select "title", text: "Bookmarks: Untagged bookmarks"
    assert_select "h1", text: "Untagged bookmarks"
    assert_select "h2", text: "Tags (0)"
    assert_select "h2", text: "Bookmarks (50)"

    assert_equal [
      # Uncommon tag "A" not available
      # Uncommon tag "B" not available
      # Uncommon tag "C" not available
      [root_path, "∅ (50)", "All bookmarks"],
      [search_untagged_path(visibility: "public"), "🔓 (25)", "Public bookmarks only"],
      [search_untagged_path(visibility: "private"), "🔒 (25)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "untagged public bookmarks" do
    list_bookmarks method(:search_untagged_path), {visibility: "public"}, {search_untagged: 1}

    assert_select "title", text: "Bookmarks: Untagged public bookmarks"
    assert_select "h1", text: "Untagged public bookmarks"
    assert_select "h2", text: "Tags (0)"
    assert_select "h2", text: "Bookmarks (25)"

    assert_equal [
      # Uncommon tag "A" not available
      # Uncommon tag "B" not available
      # Uncommon tag "C" not available
      [search_public_path, "∅ (25)", "All public bookmarks"],
      [search_untagged_path(visibility: nil), "🔓 (25)", "Include private bookmarks"],
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "untagged private bookmarks" do
    list_bookmarks method(:search_untagged_path), {visibility: "private"}, {search_untagged: 1}

    assert_select "title", text: "Bookmarks: Untagged private bookmarks"
    assert_select "h1", text: "Untagged private bookmarks"
    assert_select "h2", text: "Tags (0)"
    assert_select "h2", text: "Bookmarks (25)"

    assert_equal [
      # Uncommon tag "A" not available
      # Uncommon tag "B" not available
      # Uncommon tag "C" not available
      [search_private_path, "∅ (25)", "All private bookmarks"],
      # Public not available
      [search_untagged_path(visibility: nil), "🔒 (25)", "Include public bookmarks"],
    ], tag_links

    verify_pagination
  end

  test "logged out user" do
    sign_out users(:one)

    list_bookmarks method(:root_path)

    assert_select "title", text: "Bookmarks"
    assert_select "h1", text: "All bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (150)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id}", visibility: nil), "A (50)", 'Search by tag "A"'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "B (75)", 'Search by tag "B"'],
      [search_by_tags_path(tags: "#{@c.id}", visibility: nil), "C (50)", 'Search by tag "C"'],
      [search_untagged_path(visibility: nil), "∅ (25)", "Untagged bookmarks"],
      # Public not available
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "no tagged bookmarks" do
    Bookmark.with_tags([@a.id]).destroy_all
    Bookmark.with_tags([@b.id]).destroy_all
    Bookmark.with_tags([@c.id]).destroy_all

    list_bookmarks method(:root_path)

    assert_select "title", text: "Bookmarks"
    assert_select "h1", text: "All bookmarks"
    assert_select "h2", text: "Tags (0)"
    assert_select "h2", text: "Bookmarks (50)"

    assert_equal [
      # No tags
      # Untagged not available
      [search_public_path, "🔓 (25)", "Public bookmarks only"],
      [search_private_path, "🔒 (25)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "no untagged bookmarks" do
    Bookmark.without_tags.destroy_all

    list_bookmarks method(:root_path)

    assert_select "title", text: "Bookmarks"
    assert_select "h1", text: "All bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (250)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id}", visibility: nil), "A (100)", 'Search by tag "A"'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "B (150)", 'Search by tag "B"'],
      [search_by_tags_path(tags: "#{@c.id}", visibility: nil), "C (100)", 'Search by tag "C"'],
      # Untagged not available
      [search_public_path, "🔓 (125)", "Public bookmarks only"],
      [search_private_path, "🔒 (125)", "Private bookmarks only"],
    ], tag_links

    verify_pagination
  end

  test "no public bookmarks" do
    Bookmark.where(private: false).destroy_all

    list_bookmarks method(:root_path)

    assert_select "title", text: "Bookmarks"
    assert_select "h1", text: "All bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (150)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id}", visibility: nil), "A (50)", 'Search by tag "A"'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "B (75)", 'Search by tag "B"'],
      [search_by_tags_path(tags: "#{@c.id}", visibility: nil), "C (50)", 'Search by tag "C"'],
      [search_untagged_path(visibility: nil), "∅ (25)", "Untagged bookmarks"],
      # Public not available
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "no private bookmarks" do
    Bookmark.where(private: true).destroy_all

    list_bookmarks method(:root_path)

    assert_select "title", text: "Bookmarks"
    assert_select "h1", text: "All bookmarks"
    assert_select "h2", text: "Tags (3)"
    assert_select "h2", text: "Bookmarks (150)"

    assert_equal [
      [search_by_tags_path(tags: "#{@a.id}", visibility: nil), "A (50)", 'Search by tag "A"'],
      [search_by_tags_path(tags: "#{@b.id}", visibility: nil), "B (75)", 'Search by tag "B"'],
      [search_by_tags_path(tags: "#{@c.id}", visibility: nil), "C (50)", 'Search by tag "C"'],
      [search_untagged_path(visibility: nil), "∅ (25)", "Untagged bookmarks"],
      # Public not available
      # Private not available
    ], tag_links

    verify_pagination
  end

  test "no bookmarks" do
    Bookmark.destroy_all

    list_bookmarks method(:root_path)

    assert_select "title", text: "Bookmarks"
    assert_select "h1", text: "All bookmarks"
    assert_select "h2", text: %r{^Tags\b}, count: 0
    assert_select "h2", text: %r{^Bookmarks\b}, count: 0
    assert_select "p", text: "No bookmarks."

    assert_equal [
      # Nothing available
    ], tag_links
  end
end
