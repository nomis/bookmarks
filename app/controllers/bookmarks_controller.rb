class BookmarksController < ApplicationController
  before_action :set_bookmark, only: [:show, :edit, :update, :destroy]

  # GET /bookmarks
  # GET /bookmarks.json
  def index
    @bookmarks = Bookmark.all.includes(:tags)
  end

  # GET /bookmarks/1
  # GET /bookmarks/1.json
  def show
  end

  # GET /bookmarks/new
  def new
    @bookmark = Bookmark.new
  end

  # GET /bookmarks/1/edit
  def edit
  end

  # POST /bookmarks
  # POST /bookmarks.json
  def create
    @bookmark = Bookmark.new(bookmark_params)

    respond_to do |format|
      # Tag manipulation cannot not be done concurrently in a safe way
      @bookmark.with_advisory_lock("bookmark") do
        if @bookmark.save
          format.html { redirect_to @bookmark, notice: 'Bookmark was successfully created.' }
          format.json { render :show, status: :created, location: @bookmark }
        else
          format.html { render :new }
          format.json { render json: @bookmark.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /bookmarks/1
  # PATCH/PUT /bookmarks/1.json
  def update
    respond_to do |format|
      # Tag manipulation cannot not be done concurrently in a safe way
      @bookmark.with_advisory_lock("bookmark") do
        if @bookmark.update(bookmark_params)
          format.html { redirect_to @bookmark, notice: 'Bookmark was successfully updated.' }
          format.json { render :show, status: :ok, location: @bookmark }
        else
          format.html { render :edit }
          format.json { render json: @bookmark.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /bookmarks/1
  # DELETE /bookmarks/1.json
  def destroy
    # Tag manipulation cannot not be done concurrently in a safe way
    @bookmark.with_advisory_lock("bookmark") do
      @bookmark.destroy
    end
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Bookmark was successfully destroyed.' }
      format.json { head :no_content }
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
end
