# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class BookmarksController < ApplicationController
  MAX_TAGS = Rails.configuration.x.maximum_tags

  before_action :set_bookmark, only: [:show, :edit, :update, :delete, :destroy]
  before_action :authenticate_user!, except: [:index, :show, :search, :incremental]
  before_action :check_access, only: [:show]

  # GET /bookmarks
  # GET /bookmarks.json
  # GET /bookmarks.xml
  def index
    return unless load_bookmarks

    respond_to do |format|
      format.html { canonical_pagination(@list.pagination) }
      format.json { @bookmarks = @bookmarks.includes(:tags) }
      format.xml { @bookmarks = @bookmarks.includes(:tags) }
    end
  end

  # GET /bookmarks/1
  # GET /bookmarks/1.json
  # GET /bookmarks/1.xml
  def show; end

  # GET /bookmarks/new
  def new
    @bookmark = Bookmark.new(title: params["title"], uri: params["uri"])
  end

  # GET /bookmarks/compose
  def compose
    bookmark = Bookmark.find_by(uri: params["uri"])
    if bookmark
      redirect_to edit_bookmark_path(bookmark), notice: "Bookmark for \"#{params["title"]}\" already exists."
    else
      redirect_to new_bookmark_path(title: params["title"], uri: params["uri"])
    end
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
  # GET /tags/1,2,3.xml
  def search
    return unless load_bookmarks(params[:tags])

    respond_to do |format|
      format.html do
        return unless canonical_pagination(@list.pagination, tags: params[:tags])
        redirect_to root_path if @list.empty?
      end
      format.json { @bookmarks = @bookmarks.includes(:tags) }
      format.xml { @bookmarks = @bookmarks.includes(:tags) }
    end
  end

  # GET /incremental.js?page=...[&tags=...]
  def incremental
    return unless load_bookmarks(params[:tags])

    respond_to do |format|
      format.js
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bookmark
    @bookmark = Bookmark.find(params[:id])
  end

  def check_access
    authenticate_user! if @bookmark.private?
  end

  # Only allow a list of trusted parameters through.
  def bookmark_params
    params.require(:bookmark).permit(:title, :uri, :tags_string, :private)
  end

  # Load bookmarks for index, search or incremental output
  def load_bookmarks(tags = nil)
    bookmarks = Bookmark.for_user(user_signed_in?)
    bookmark_tags = BookmarkTag.for_user(user_signed_in?)
    filter_tags = tags ? Set.new(tags.split(",").map { |tag| Integer(tag) }) : Set.new()

    if !filter_tags.empty?
      validate_search(filter_tags)
      return false unless canonical_search(filter_tags)

      bookmarks = bookmarks.with_tags(filter_tags)
      bookmark_tags = bookmark_tags.with_tags(filter_tags)
    end

    list = ListFacade.new(params, bookmarks, bookmark_tags, filter_tags)

    respond_to do |format|
      format.html { @list = list }
      format.js { @list = list }
      format.json { @bookmarks = bookmarks }
      format.xml { @bookmarks = bookmarks }
    end
    true
  end

  # Validate search by tags
  def validate_search(filter_tags)
    return unless filter_tags.size > MAX_TAGS

    raise Bookmark.human_attribute_name(:tags_string) + " limit reached (maximum is " \
            + ActionController::Base.helpers.pluralize(MAX_TAGS, "tag") + ")"
  end

  # Canonicalise search URL
  def canonical_search(filter_tags)
    canonical_filter_tags = filter_tags.sort(&NaturalSort).join(",")
    if params[:tags] == canonical_filter_tags
      true
    else
      respond_to do |format|
        format.html { redirect_to url_for(tags: canonical_filter_tags, page: params[:page]) }
        format.json { redirect_to url_for(tags: canonical_filter_tags, format: "json") }
        format.xml { redirect_to url_for(tags: canonical_filter_tags, format: "xml") }
        format.js { head :bad_request }
      end
      false
    end
  end

  # Canonicalise pagination URL
  def canonical_pagination(pagination, **args)
    if pagination.overflow?
      redirect_to url_for(args.merge(page: pagination.last > 1 ? pagination.last : nil))
      false
    elsif params[:page].present? && (pagination.page == 1 || params[:page] != pagination.page.to_s)
      redirect_to url_for(args.merge(page: pagination.page > 1 ? pagination.page : nil))
      false
    else
      true
    end
  end
end
