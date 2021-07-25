# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

class BookmarksController < ApplicationController
  before_action :set_bookmark, only: [:show, :edit, :update, :delete, :destroy]
  before_action :authenticate_user!, except: [:index, :show, :search]

  # GET /bookmarks
  # GET /bookmarks.json
  def index
    respond_to do |format|
      format.html { @list = ListFacade.new }
      format.json { @bookmarks = Bookmark.all.includes(:tags) }
    end
  end

  # GET /bookmarks/1
  # GET /bookmarks/1.json
  def show; end

  # GET /bookmarks/new
  def new
    @bookmark = Bookmark.new
  end

  # GET /bookmarks/1/edit
  def edit; end

  # POST /bookmarks
  # POST /bookmarks.json
  def create
    @bookmark = Bookmark.new(bookmark_params)

    respond_to do |format|
      # Tag manipulation cannot not be done concurrently in a safe way
      if @bookmark.with_advisory_lock("bookmark") { @bookmark.save }
        format.html { redirect_to @bookmark, notice: "Bookmark was successfully created." }
        format.json { render :show, status: :created, location: @bookmark }
      else
        format.html { render :new }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bookmarks/1
  # PATCH/PUT /bookmarks/1.json
  def update
    respond_to do |format|
      # Tag manipulation cannot not be done concurrently in a safe way
      if @bookmark.with_advisory_lock("bookmark") { @bookmark.update(bookmark_params) }
        format.html { redirect_to @bookmark, notice: "Bookmark was successfully updated." }
        format.json { render :show, status: :ok, location: @bookmark }
      else
        format.html { render :edit }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /bookmarks/1/delete
  def delete
    raise ActionController::InvalidAuthenticityToken unless any_authenticity_token_valid?
    return unless request.get?

    # Tag manipulation cannot not be done concurrently in a safe way
    @bookmark.with_advisory_lock("bookmark") { @bookmark.destroy }

    redirect_to root_path, notice: "Bookmark was successfully deleted."
  end

  # DELETE /bookmarks/1
  # DELETE /bookmarks/1.json
  def destroy
    # Tag manipulation cannot not be done concurrently in a safe way
    @bookmark.with_advisory_lock("bookmark") { @bookmark.destroy }

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Bookmark was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # GET /tags/1,2,3
  # GET /tags/1,2,3.json
  def search
    filter_tags = Set.new(params[:tags].split(",").map { |tag| Integer(tag) })

    validate_search(filter_tags)
    return unless canonical_search(filter_tags)

    respond_to do |format|
      format.html do
        @list = ListFacade.new(
          Bookmark.with_tags(filter_tags),
          BookmarkTag.for_bookmarks_with_tags(filter_tags),
          filter_tags
        )
      end
      format.json { @bookmarks = Bookmark.with_tags(filter_tags).includes(:tags) }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bookmark
    @bookmark = Bookmark.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def bookmark_params
    params.require(:bookmark).permit(:title, :uri, :tags_string)
  end

  # Validate search by tags
  def validate_search(filter_tags)
    return unless filter_tags.size > Bookmark::MAX_TAGS

    raise Bookmark.human_attribute_name(:tags_string) + " limit reached (maximum is " \
            + ActionController::Base.helpers.pluralize(Bookmark::MAX_TAGS, "tag") + ")"
  end

  # Canonicalise search URL
  def canonical_search(filter_tags)
    canonical_filter_tags = filter_tags.sort(&NaturalSort).join(",")
    return true if params[:tags] == canonical_filter_tags

    respond_to do |format|
      format.html { redirect_to url_for(tags: canonical_filter_tags) }
      format.json { redirect_to url_for(tags: canonical_filter_tags, format: "json") }
    end
    false
  end
end
