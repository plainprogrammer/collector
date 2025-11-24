class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[show edit update destroy]

  def index
    @collections = Collection.includes(:storage_units, :items).order(updated_at: :desc)
  end

  def show
    @storage_units = @collection.storage_units.where(parent_id: nil).includes(:children, :items)
  end

  def new
    @collection = Collection.new
  end

  def create
    @collection = Collection.new(collection_params)

    if @collection.save
      respond_to do |format|
        format.html { redirect_to @collection, notice: "Collection was successfully created." }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @collection.update(collection_params)
      respond_to do |format|
        format.html { redirect_to @collection, notice: "Collection was successfully updated." }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection.destroy

    respond_to do |format|
      format.html { redirect_to collections_path, notice: "Collection was successfully deleted." }
      format.turbo_stream
    end
  end

  private

  def set_collection
    @collection = Collection.find(params[:id])
  end

  def collection_params
    params.require(:collection).permit(:name, :description)
  end
end
