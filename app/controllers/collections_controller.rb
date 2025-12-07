class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[show edit update destroy statistics]

  def index
    @collections = Collection.includes(:storage_units, :items).order(updated_at: :desc)
  end

  def show
    @storage_units = @collection.storage_units.where(parent_id: nil).includes(:children, :items)
    @current_tab = params[:tab] || "storage"
  end

  def statistics
    @stats = CollectionStatistics.new(@collection)
  end

  def new
    @collection = Collection.new
  end

  def create
    @collection = Collection.new(collection_params)

    if @collection.save
      redirect_to @collection, notice: "Collection was successfully created.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @collection.update(collection_params)
      redirect_to @collection, notice: "Collection was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection.destroy
    redirect_to collections_path, notice: "Collection was successfully deleted.", status: :see_other
  end

  private

  def set_collection
    @collection = Collection.find(params[:id])
  end

  def collection_params
    params.require(:collection).permit(:name, :description)
  end
end
