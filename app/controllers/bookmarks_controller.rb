# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class BookmarksController < ApplicationController
  MAX_TAGS = Rails.configuration.x.maximum_tags

  before_action :set_bookmark, only: [:show, :edit, :update, :delete, :destroy]
  before_action :authenticate_user!, except: [:index, :show, :search_tagged, :search_untagged, :incremental, :compose]
  before_action :check_access, only: [:show]

  # Not called if authenticate_user! is used
  after_action :delete_cookies

  # GET /
  # GET /bookmarks
  # GET /bookmarks.json
  # GET /bookmarks.xml
  # GET /tags/1,2,3
  # GET /tags/1,2,3.json
  # GET /tags/1,2,3.xml
  # GET /public/tags/1,2,3
  # GET /public/tags/1,2,3.json
  # GET /public/tags/1,2,3.xml
  # GET /private/tags/1,2,3
  # GET /private/tags/1,2,3.json
  # GET /private/tags/1,2,3.xml
  # GET /untagged
  # GET /untagged.json
  # GET /untagged.xml
  # GET /public/untagged
  # GET /public/untagged.json
  # GET /public/untagged.xml
  # GET /private/untagged
  # GET /private/untagged.json
  # GET /private/untagged.xml
  def index
    return unless load_bookmarks(params[:tags], params[:untagged] == true, params[:visibility])

    respond_to do |format|
      format.html do
        return unless canonical_pagination(@list.pagination, tags: params[:tags])
        return unless canonical_search(params[:tags])
        redirect_to root_path if @list.empty?
      end
      format.json { @bookmarks = @bookmarks.includes(:tags) }
      format.xml { @bookmarks = @bookmarks.includes(:tags) }
    end
  end

  # GET /bookmarks/1
  # GET /bookmarks/1.json
  # GET /bookmarks/1.xml
  def show
    respond_to do |format|
      format.html do
        @bookmark = BookmarkFacade.new(@bookmark, Set.new) do |tags|
          tags.for_user(user_signed_in?).with_count.order(:key)
        end
      end
      format.json
      format.xml
    end
  end

  # GET /bookmarks/new
  def new
    @bookmark = Bookmark.new(title: params["title"], uri: params["uri"])
  end

  # GET /bookmarks/compose
  def compose
    # Initiate client redirect to obtain SameSite=Strict cookies
    helpers.no_session!
  end

  # GET /bookmarks/compose_with_session
  def compose_with_session
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
        format.html { redirect_to bookmark_path(@bookmark, helpers.auto_params_context), notice: "Bookmark was successfully created." }
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
        format.html { redirect_to bookmark_path(@bookmark, helpers.auto_params_context), notice: "Bookmark was successfully updated." }
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

    redirect_to helpers.auto_root_path, notice: "Bookmark was successfully deleted."
  end

  # DELETE /bookmarks/1
  # DELETE /bookmarks/1.json
  def destroy
    # Tag manipulation cannot not be done concurrently in a safe way
    @bookmark.with_advisory_lock("bookmark") { @bookmark.destroy }

    respond_to do |format|
      format.html { redirect_to helpers.auto_root_path, notice: "Bookmark was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # GET /incremental.json?page=...[&search_tags=...][&search_untagged=1][&search_visibility=...]
  def incremental
    checked_params = helpers.auto_params_context
    return unless load_bookmarks(checked_params[:search_tags],
      checked_params[:search_untagged],
      checked_params[:search_visibility])

    respond_to do |format|
      format.json
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
  def load_bookmarks(tags_param, untagged_only, visibility)
    if tags_param.present? && untagged_only
      render(status: :bad_request)
      return false
    elsif !visibility.nil?
      if !["public", "private"].include?(visibility)
        render(status: :bad_request)
        return false
      else
        # Only users are allowed to search by visibility
        authenticate_user!
      end
    end

    filter_tags = tags_param ? Set.new(tags_param.split(",").map(&:to_i)) : Set.new()

    @bookmarks = Bookmark.for_user(user_signed_in?)
    tags = Tag.for_user(user_signed_in?)

    if visibility.present?
      @bookmarks = @bookmarks.where(private: visibility == "private")
      tags = tags.joins(:bookmarks).merge(Bookmark.where(private: visibility == "private"))
    end

    if !filter_tags.empty?
      validate_search(filter_tags)

      @bookmarks = @bookmarks.with_tags(filter_tags)
      tags = tags.common_tags(filter_tags)
    end

    if untagged_only
      @bookmarks = @bookmarks.without_tags
      tags = tags.none
    end

    @list = ListFacade.new(params, @bookmarks, tags, filter_tags, untagged_only, visibility&.to_sym)
    true
  end

  # Validate search by tags
  def validate_search(filter_tags)
    return unless filter_tags.size > MAX_TAGS

    raise Bookmark.human_attribute_name(:tags_string) + " limit reached (maximum is " \
            + ActionController::Base.helpers.pluralize(MAX_TAGS, "tag") + ")"
  end

  # Canonicalise search URL
  def canonical_search(tags_param)
    return true if tags_param.nil?

    canonical_filter_tags = tags_param.split(",").map(&:to_i).sort(&NaturalSort).join(",")
    if tags_param == canonical_filter_tags
      true
    else
      respond_to do |format|
        format.html { redirect_to url_for(tags: canonical_filter_tags, page: params[:page]) }
        format.json { redirect_to url_for(tags: canonical_filter_tags, page: params[:page], format: "json") }
        format.xml { redirect_to url_for(tags: canonical_filter_tags, page: params[:page], format: "xml") }
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
