# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

require "rails_helper"

# The list of bookmarks can be filtered by those that have tags (as well as
# those that have no tags) or public/private visibility.
#
# Availability of these options is limited to when they would return more than
# 0 bookmarks, or if they are already applied (so that they can be removed).
#
# All options are shown under the "Tags" heading but the tag count only includes
# real tags (so it may be 0). When there are no options to select from the
# "Tags" heading is omitted entirely.
#
# Results are paginated but the count in the "Bookmarks" heading shows the total
# for all pages. Incremental pagination needs to be verified to ensure that it
# and the next incremental pagination URL requests the same filter parameters as
# the list page itself.
#
# If a list of bookmarks would be empty then a redirect is made to the root
# page that displays all bookmarks.
RSpec.describe "Bookmarks#index", type: :feature do
  before(:all) do
    # Fewer items per page so that there are more pages
    Pagy::VARS[:items] = 10

    Bookmark.transaction do
      User.destroy_all
      remove_test_data
    end
  end

  def user
    @user ||= FactoryBot.create(:user)
  end

  def generate_test_data(with_tags: true, with_public: true, with_private: true, with_untagged: true)
    tags_strings = []
    tags_strings << "" if with_untagged
    tags_strings += ["A", "B", "C", "A B", "B C"] if with_tags

    privates = []
    privates << false if with_public
    privates << true if with_private

    Bookmark.transaction do
      n = 0
      tags_strings.each do |tags_string|
        privates.each do |private|
          (1..25).each do |i|
            b = Bookmark.create(
              title: "Test #{tags_string} #{private ? "private" : "public"} #{i}",
              uri: "https://#{n}.test/")
            b.tags_string = tags_string
            b.private = private
            b.save!

            n += 1
          end
        end
      end
    end
  end

  def remove_test_data
    Bookmark.transaction do
      Bookmark.destroy_all
      Tag.destroy_all
    end
  end

  let(:a_id) { Tag.find_by(name: "A").id }
  let(:b_id) { Tag.find_by(name: "B").id }
  let(:c_id) { Tag.find_by(name: "C").id }

  after(:all) do
    remove_test_data
  end

  shared_examples "list of bookmarks" do
    def query(others = {})
      args.merge(others)
    end

    def incremental_query(others = {})
      {format: "json"}
        .merge(query.map { |key, value| ["search_#{key}", value] }.to_h)
        .merge(incremental_args)
        .merge(others)
    end

    def text_or_h(value)
      if value.respond_to?(:to_h)
        value.to_h
      else
        {text: value}
      end
    end

    let(:first_page) do
      visit path.call(query)
      page
    end

    context "the first page" do
      it "has a successful response" do
        expect(first_page).to have_http_status(:success)
      end

      it "is not redirected" do
        expect(first_page).to have_current_path(path.call(query))
      end

      it "has a title" do
        expect(first_page.title).to eq(title)
      end

      it "has a description heading" do
        expect(first_page).to have_css("h1", text_or_h(description))
      end

      it "has a tags heading" do
        expect(first_page).to have_css("h2", text_or_h(tags_heading))
      end

      it "has a bookmarks heading" do
        expect(first_page).to have_css("h2", text_or_h(bookmarks_heading))
      end

      it "has tag links" do
        expect(first_page.find_all("ul.main.tags li a").map do |link|
         [link["href"], link.text, link["title"]]
        end).to eq(tag_links)
      end
    end
  end

  shared_examples "paginated list of bookmarks" do
    it_behaves_like "list of bookmarks" do
      context "the first page" do
        it "has a second page" do
          expect(first_page).to have_link("2", href: path.call(query(page: 2)))
          expect(first_page).to have_link("Next ›", href: path.call(query(page: 2)))
        end

        def next_incremental
          first_page.find("#more_link", visible: false)["data-href"] 
        end

        it "has an incremental href for page 2" do
          expect(next_incremental).to eq(incremental_bookmark_path(incremental_query(page: 2)))
        end
      end

      context "the second page incremental data", type: :request do
        let(:this_response) do
          get incremental_bookmark_path(incremental_query(page: 2))
          response
        end

        it "has a successful response" do
          expect(this_response).to have_http_status(:success)
        end

        let(:next_incremental_json) do
          Nokogiri::HTML(this_response.parsed_body["pagination"]).css("#more_link")[0]["data-href"]
        end

        it "has an incremental href for page 3" do
          expect(next_incremental_json).to eq(incremental_bookmark_path(incremental_query(page: 3)))
        end
      end
    end
  end

  shared_examples "empty list of bookmarks" do
    it_behaves_like "list of bookmarks" do
      let(:tags_heading) { {text: %r{^Tags\b}, count: 0} }
      let(:bookmarks_heading) { {text: %r{^Bookmarks\b}, count: 0} }

      let(:tag_links) do [
        # Nothing available
      ] end

      it "has no bookmarks" do
        expect(first_page).to have_css("p", text: "No bookmarks.")
      end
    end
  end

  shared_examples "no search results" do
    it "redirects to the root page" do
      visit path.call(args)
      expect(page).to have_current_path(root_path)
    end
  end

  describe "with all test data" do
    before(:all) do
      generate_test_data
    end

    after(:all) do
      remove_test_data
    end

    describe "when signed in" do
      before(:each) do
        sign_in user
      end

      describe "all bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (300)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: nil), "A (100)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "B (150)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: nil), "C (100)", 'Search by tag "C"'],
            [search_untagged_path(visibility: nil), "∅ (50)", "Untagged bookmarks"],
            [search_public_path, "🔓 (150)", "Public bookmarks only"],
            [search_private_path, "🔒 (150)", "Private bookmarks only"],
          ] end
        end
      end

      describe "public bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_public_path) }
          let(:args) { {} }
          let(:incremental_args) { {search_visibility: "public"} }

          let(:title) { "Bookmarks: Public bookmarks" }
          let(:description) { "Public bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (150)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: "public"), "A (50)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: "public"), "B (75)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: "public"), "C (50)", 'Search by tag "C"'],
            [search_untagged_path(visibility: "public"), "∅ (25)", "Untagged bookmarks"],
            [root_path, "🔓 (150)", "All bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "private bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_private_path) }
          let(:args) { {} }
          let(:incremental_args) { {search_visibility: "private"} }

          let(:title) { "Bookmarks: Private bookmarks" }
          let(:description) { "Private bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (150)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: "private"), "A (50)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: "private"), "B (75)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: "private"), "C (50)", 'Search by tag "C"'],
            [search_untagged_path(visibility: "private"), "∅ (25)", "Untagged bookmarks"],
            # Public not available
            [root_path, "🔒 (150)", "All bookmarks"],
          ] end
        end
      end

      describe "bookmarks with tag A" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{a_id}", visibility: nil} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: A" }
          let(:description) { "Search bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (100)" }

          let(:tag_links) do [
            [root_path, "A (100)", "All bookmarks"],
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: nil), "B (50)", 'Add tag "B" to search'],
            # Uncommon tag "C" not available
            # Untagged not available
            [search_by_tags_path(tags: "#{a_id}", visibility: "public"), "🔓 (50)", "Public bookmarks only"],
            [search_by_tags_path(tags: "#{a_id}", visibility: "private"), "🔒 (50)", "Private bookmarks only"],
          ] end
        end
      end

      describe "public bookmarks with tag A" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{a_id}", visibility: "public"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: A (public bookmarks only)" }
          let(:description) { "Search public bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            [search_public_path, "A (50)", "All public bookmarks"],
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: "public"), "B (25)", 'Add tag "B" to search'],
            # Uncommon tag "C" not available
            # Untagged not available
            [search_by_tags_path(tags: "#{a_id}", visibility: nil), "🔓 (50)", "Include private bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "private bookmarks with tag A" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{a_id}", visibility: "private"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: A (private bookmarks only)" }
          let(:description) { "Search private bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            [search_private_path, "A (50)", "All private bookmarks"],
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: "private"), "B (25)", 'Add tag "B" to search'],
            # Uncommon tag "C" not available
            # Untagged not available
            # Public not available
            [search_by_tags_path(tags: "#{a_id}", visibility: nil), "🔒 (50)", "Include public bookmarks"],
          ] end
        end
      end

      describe "bookmarks with tag A and B" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{a_id},#{b_id}", visibility: nil} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 2 tags: A, B" }
          let(:description) { "Search bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "A (50)", 'Remove tag "A" from search'],
            [search_by_tags_path(tags: "#{a_id}", visibility: nil), "B (50)", 'Remove tag "B" from search'],
            # Uncommon tag "C" not available
            # Untagged not available
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: "public"), "🔓 (25)", "Public bookmarks only"],
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: "private"), "🔒 (25)", "Private bookmarks only"],
          ] end
        end
      end

      describe "public bookmarks with tag A and B" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{a_id},#{b_id}", visibility: "public"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 2 tags: A, B (public bookmarks only)" }
          let(:description) { "Search public bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{b_id}", visibility: "public"), "A (25)", 'Remove tag "A" from search'],
            [search_by_tags_path(tags: "#{a_id}", visibility: "public"), "B (25)", 'Remove tag "B" from search'],
            # Uncommon tag "C" not available
            # Untagged not available
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: nil), "🔓 (25)", "Include private bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "private bookmarks with tag A and B" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{a_id},#{b_id}", visibility: "private"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 2 tags: A, B (private bookmarks only)" }
          let(:description) { "Search private bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{b_id}", visibility: "private"), "A (25)", 'Remove tag "A" from search'],
            [search_by_tags_path(tags: "#{a_id}", visibility: "private"), "B (25)", 'Remove tag "B" from search'],
            # Uncommon tag "C" not available
            # Untagged not available
            # Public not available
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: nil), "🔒 (25)", "Include public bookmarks"],
          ] end
        end
      end

      describe "bookmarks with tag A and C" do
        it_behaves_like "no search results" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{a_id},#{c_id}", visibility: nil} }
        end
      end

      describe "bookmarks with tag B" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{b_id}", visibility: nil} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: B" }
          let(:description) { "Search bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (150)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: nil), "A (50)", 'Add tag "A" to search'],
            [root_path, "B (150)", "All bookmarks"],
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: nil), "C (50)", 'Add tag "C" to search'],
            # Untagged not available
            [search_by_tags_path(tags: "#{b_id}", visibility: "public"), "🔓 (75)", "Public bookmarks only"],
            [search_by_tags_path(tags: "#{b_id}", visibility: "private"), "🔒 (75)", "Private bookmarks only"],
          ] end
        end
      end

      describe "public bookmarks with tag B" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{b_id}", visibility: "public"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: B (public bookmarks only)" }
          let(:description) { "Search public bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (75)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: "public"), "A (25)", 'Add tag "A" to search'],
            [search_public_path, "B (75)", "All public bookmarks"],
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: "public"), "C (25)", 'Add tag "C" to search'],
            # Untagged not available
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "🔓 (75)", "Include private bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "private bookmarks with tag B" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{b_id}", visibility: "private"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: B (private bookmarks only)" }
          let(:description) { "Search private bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (75)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id},#{b_id}", visibility: "private"), "A (25)", 'Add tag "A" to search'],
            [search_private_path, "B (75)", "All private bookmarks"],
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: "private"), "C (25)", 'Add tag "C" to search'],
            # Untagged not available
            # Public not available
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "🔒 (75)", "Include public bookmarks"],
          ] end
        end
      end

      describe "bookmarks with tag B and C" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{b_id},#{c_id}", visibility: nil} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 2 tags: B, C" }
          let(:description) { "Search bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            [search_by_tags_path(tags: "#{c_id}", visibility: nil), "B (50)", 'Remove tag "B" from search'],
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "C (50)", 'Remove tag "C" from search'],
            # Untagged not available
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: "public"), "🔓 (25)", "Public bookmarks only"],
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: "private"), "🔒 (25)", "Private bookmarks only"],
          ] end
        end
      end

      describe "public bookmarks with tag B and C" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{b_id},#{c_id}", visibility: "public"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 2 tags: B, C (public bookmarks only)" }
          let(:description) { "Search public bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            [search_by_tags_path(tags: "#{c_id}", visibility: "public"), "B (25)", 'Remove tag "B" from search'],
            [search_by_tags_path(tags: "#{b_id}", visibility: "public"), "C (25)", 'Remove tag "C" from search'],
            # Untagged not available
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: nil), "🔓 (25)", "Include private bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "private bookmarks with tag B and C" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{b_id},#{c_id}", visibility: "private"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 2 tags: B, C (private bookmarks only)" }
          let(:description) { "Search private bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            [search_by_tags_path(tags: "#{c_id}", visibility: "private"), "B (25)", 'Remove tag "B" from search'],
            [search_by_tags_path(tags: "#{b_id}", visibility: "private"), "C (25)", 'Remove tag "C" from search'],
            # Untagged not available
            # Public not available
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: nil), "🔒 (25)", "Include public bookmarks"],
          ] end

          end
        end

      describe "bookmarks with tag C" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{c_id}", visibility: nil} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: C" }
          let(:description) { "Search bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (100)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: nil), "B (50)", 'Add tag "B" to search'],
            [root_path, "C (100)", "All bookmarks"],
            # Untagged not available
            [search_by_tags_path(tags: "#{c_id}", visibility: "public"), "🔓 (50)", "Public bookmarks only"],
            [search_by_tags_path(tags: "#{c_id}", visibility: "private"), "🔒 (50)", "Private bookmarks only"],
          ] end

          end
        end

      describe "public bookmarks with tag C" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{c_id}", visibility: "public"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: C (public bookmarks only)" }
          let(:description) { "Search public bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: "public"), "B (25)", 'Add tag "B" to search'],
            [search_public_path, "C (50)", "All public bookmarks"],
            # Untagged not available
            [search_by_tags_path(tags: "#{c_id}", visibility: nil), "🔓 (50)", "Include private bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "private bookmarks with tag C" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_by_tags_path) }
          let(:args) { {tags: "#{c_id}", visibility: "private"} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks: Search by 1 tag: C (private bookmarks only)" }
          let(:description) { "Search private bookmarks" }
          let(:tags_heading) { "Tags (2)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            [search_by_tags_path(tags: "#{b_id},#{c_id}", visibility: "private"), "B (25)", 'Add tag "B" to search'],
            [search_private_path, "C (50)", "All private bookmarks"],
            # Untagged not available
            # Public not available
            [search_by_tags_path(tags: "#{c_id}", visibility: nil), "🔒 (50)", "Include public bookmarks"],
          ] end
        end
      end

      describe "untagged bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_untagged_path) }
          let(:args) { {visibility: nil} }
          let(:incremental_args) { {search_untagged: 1} }

          let(:title) { "Bookmarks: Untagged bookmarks" }
          let(:description) { "Untagged bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            # Uncommon tag "B" not available
            # Uncommon tag "C" not available
            [root_path, "∅ (50)", "All bookmarks"],
            [search_untagged_path(visibility: "public"), "🔓 (25)", "Public bookmarks only"],
            [search_untagged_path(visibility: "private"), "🔒 (25)", "Private bookmarks only"],
          ] end
        end
      end

      describe "untagged public bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_untagged_path) }
          let(:args) { {visibility: "public"} }
          let(:incremental_args) { {search_untagged: 1} }

          let(:title) { "Bookmarks: Untagged public bookmarks" }
          let(:description) { "Untagged public bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            # Uncommon tag "B" not available
            # Uncommon tag "C" not available
            [search_public_path, "∅ (25)", "All public bookmarks"],
            [search_untagged_path(visibility: nil), "🔓 (25)", "Include private bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "untagged private bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_untagged_path) }
          let(:args) { {visibility: "private"} }
          let(:incremental_args) { {search_untagged: 1} }

          let(:title) { "Bookmarks: Untagged private bookmarks" }
          let(:description) { "Untagged private bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            # Uncommon tag "A" not available
            # Uncommon tag "B" not available
            # Uncommon tag "C" not available
            [search_private_path, "∅ (25)", "All private bookmarks"],
            # Public not available
            [search_untagged_path(visibility: nil), "🔒 (25)", "Include public bookmarks"],
          ] end
        end
      end
    end # when signed in

    describe "when not signed in" do
      describe "all bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (150)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: nil), "A (50)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "B (75)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: nil), "C (50)", 'Search by tag "C"'],
            [search_untagged_path(visibility: nil), "∅ (25)", "Untagged bookmarks"],
            # Public not available
            # Private not available
          ] end
        end
      end
    end
  end # with all test data

  describe "when signed in" do
    before(:each) do
      sign_in user
    end

    describe "without tagged bookmarks" do
      before(:all) do
        generate_test_data(with_tags: false)
      end

      after(:all) do
        remove_test_data
      end

      describe "all bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            # No tags
            # Untagged not available
            [search_public_path, "🔓 (25)", "Public bookmarks only"],
            [search_private_path, "🔒 (25)", "Private bookmarks only"],
          ] end
        end
      end

      describe "untagged bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_untagged_path) }
          let(:args) { {visibility: nil} }
          let(:incremental_args) { {search_untagged: 1} }

          let(:title) { "Bookmarks: Untagged bookmarks" }
          let(:description) { "Untagged bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (50)" }

          let(:tag_links) do [
            # No tags
            [root_path, "∅ (50)", "All bookmarks"],
            [search_untagged_path(visibility: "public"), "🔓 (25)", "Public bookmarks only"],
            [search_untagged_path(visibility: "private"), "🔒 (25)", "Private bookmarks only"],
          ] end
        end
      end
    end # without tagged bookmarks

    describe "without untagged bookmarks" do
      before(:all) do
        generate_test_data(with_untagged: false)
      end

      after(:all) do
        remove_test_data
      end

      describe "all bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (250)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: nil), "A (100)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "B (150)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: nil), "C (100)", 'Search by tag "C"'],
            # Untagged not available
            [search_public_path, "🔓 (125)", "Public bookmarks only"],
            [search_private_path, "🔒 (125)", "Private bookmarks only"],
          ] end
        end
      end

      describe "untagged bookmarks" do
        it_behaves_like "no search results" do
          let(:path) { method(:search_untagged_path) }
          let(:args) { {visibility: nil} }
        end
      end
    end # without untagged bookmarks

    describe "without public bookmarks" do
      before(:all) do
        generate_test_data(with_public: false)
      end

      after(:all) do
        remove_test_data
      end

      describe "all bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (150)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: nil), "A (50)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "B (75)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: nil), "C (50)", 'Search by tag "C"'],
            [search_untagged_path(visibility: nil), "∅ (25)", "Untagged bookmarks"],
            # Public not available
            # Private not available
          ] end
        end
      end

      describe "private bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_private_path) }
          let(:args) { {} }
          let(:incremental_args) { {search_visibility: "private"} }

          let(:title) { "Bookmarks: Private bookmarks" }
          let(:description) { "Private bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (150)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: "private"), "A (50)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: "private"), "B (75)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: "private"), "C (50)", 'Search by tag "C"'],
            [search_untagged_path(visibility: "private"), "∅ (25)", "Untagged bookmarks"],
            # Public not available
            [root_path, "🔒 (150)", "All bookmarks"],
          ] end
        end
      end

      describe "public bookmarks" do
        it_behaves_like "no search results" do
          let(:path) { method(:search_public_path) }
          let(:args) { {} }
        end
      end
    end # without public bookmarks

    describe "without private bookmarks" do
      before(:all) do
        generate_test_data(with_private: false)
      end

      after(:all) do
        remove_test_data
      end

      describe "all bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (150)" }
          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: nil), "A (50)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: nil), "B (75)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: nil), "C (50)", 'Search by tag "C"'],
            [search_untagged_path(visibility: nil), "∅ (25)", "Untagged bookmarks"],
            # Public not available
            # Private not available
          ] end
        end
      end

      describe "public bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_public_path) }
          let(:args) { {} }
          let(:incremental_args) { {search_visibility: "public"} }

          let(:title) { "Bookmarks: Public bookmarks" }
          let(:description) { "Public bookmarks" }
          let(:tags_heading) { "Tags (3)" }
          let(:bookmarks_heading) { "Bookmarks (150)" }

          let(:tag_links) do [
            [search_by_tags_path(tags: "#{a_id}", visibility: "public"), "A (50)", 'Search by tag "A"'],
            [search_by_tags_path(tags: "#{b_id}", visibility: "public"), "B (75)", 'Search by tag "B"'],
            [search_by_tags_path(tags: "#{c_id}", visibility: "public"), "C (50)", 'Search by tag "C"'],
            [search_untagged_path(visibility: "public"), "∅ (25)", "Untagged bookmarks"],
            [root_path, "🔓 (150)", "All bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "private bookmarks" do
        it_behaves_like "no search results" do
          let(:path) { method(:search_private_path) }
          let(:args) { {} }
        end
      end
    end # without private bookmarks

    describe "without tagged or public bookmarks" do
      before(:all) do
        generate_test_data(with_tags: false, with_public: false)
      end

      after(:all) do
        remove_test_data
      end

      describe "all bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
          let(:tags_heading) { {text: %r{^Tags\b}, count: 0} }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            # No tags
            # Untagged not available
            # Public not available
            # Private not available
          ] end
        end
      end

      describe "untagged bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_untagged_path) }
          let(:args) { {visibility: nil} }
          let(:incremental_args) { {search_untagged: 1} }

          let(:title) { "Bookmarks: Untagged bookmarks" }
          let(:description) { "Untagged bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            # No tags
            [root_path, "∅ (25)", "All bookmarks"],
            # Public not available
            # Private not available
          ] end
        end
      end

      describe "private bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_private_path) }
          let(:args) { {} }
          let(:incremental_args) { {search_visibility: "private"} }

          let(:title) { "Bookmarks: Private bookmarks" }
          let(:description) { "Private bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
           # No tags
            # Untagged not available
            # Public not available
            [root_path, "🔒 (25)", "All bookmarks"],
          ] end
        end
      end

      describe "public bookmarks" do
        it_behaves_like "no search results" do
          let(:path) { method(:search_public_path) }
          let(:args) { {} }
        end
      end
    end # without tagged or public bookmarks

    describe "without tagged or private bookmarks" do
      before(:all) do
        generate_test_data(with_tags: false, with_private: false)
      end

      after(:all) do
        remove_test_data
      end

      describe "all bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
          let(:tags_heading) { {text: %r{^Tags\b}, count: 0} }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            # No tags
            # Untagged not available
            # Public not available
            # Private not available
          ] end
        end
      end

      describe "untagged bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_untagged_path) }
          let(:args) { {visibility: nil} }
          let(:incremental_args) { {search_untagged: 1} }

          let(:title) { "Bookmarks: Untagged bookmarks" }
          let(:description) { "Untagged bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
            # No tags
            [root_path, "∅ (25)", "All bookmarks"],
            # Public not available
            # Private not available
          ] end
        end
      end

      describe "public bookmarks" do
        it_behaves_like "paginated list of bookmarks" do
          let(:path) { method(:search_public_path) }
          let(:args) { {} }
          let(:incremental_args) { {search_visibility: "public"} }

          let(:title) { "Bookmarks: Public bookmarks" }
          let(:description) { "Public bookmarks" }
          let(:tags_heading) { "Tags (0)" }
          let(:bookmarks_heading) { "Bookmarks (25)" }

          let(:tag_links) do [
           # No tags
            # Untagged not available
            [root_path, "🔓 (25)", "All bookmarks"],
            # Private not available
          ] end
        end
      end

      describe "private bookmarks" do
        it_behaves_like "no search results" do
          let(:path) { method(:search_private_path) }
          let(:args) { {} }
        end
      end
    end # without tagged or public bookmarks

    describe "with no bookmarks" do
      before(:all) do
        remove_test_data
      end

      describe "all bookmarks" do
        it_behaves_like "empty list of bookmarks" do
          let(:path) { method(:root_path) }
          let(:args) { {} }
          let(:incremental_args) { {} }

          let(:title) { "Bookmarks" }
          let(:description) { "All bookmarks" }
        end
      end
    end # with no bookmarks
  end # when signed in
end
