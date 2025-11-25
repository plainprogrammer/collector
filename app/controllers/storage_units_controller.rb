class StorageUnitsController < ApplicationController
  before_action :set_collection, only: %i[index new create]
  before_action :set_storage_unit, only: %i[show edit update destroy]

  def index
    @storage_units = @collection.storage_units.where(parent_id: nil).includes(:children, :items)
  end

  def show
    @children = @storage_unit.children.includes(:children, :items)
  end

  def new
    @storage_unit = @collection.storage_units.build
    @storage_unit.parent_id = params[:parent_id] if params[:parent_id].present?
    @available_parents = @collection.storage_units.where.not(storage_unit_type: :loose)
  end

  def create
    @storage_unit = @collection.storage_units.build(storage_unit_params)

    if @storage_unit.save
      redirect_to @collection, notice: "Storage unit was successfully created.", status: :see_other
    else
      @available_parents = @collection.storage_units.where.not(storage_unit_type: :loose)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @collection = @storage_unit.collection
    @available_parents = @collection.storage_units
      .where.not(id: @storage_unit.id)
      .where.not(storage_unit_type: :loose)
  end

  def update
    if @storage_unit.update(storage_unit_params)
      redirect_to @storage_unit.collection, notice: "Storage unit was successfully updated.", status: :see_other
    else
      @collection = @storage_unit.collection
      @available_parents = @collection.storage_units
        .where.not(id: @storage_unit.id)
        .where.not(storage_unit_type: :loose)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    collection = @storage_unit.collection
    @storage_unit.destroy

    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "Storage unit was successfully deleted." }
      format.html { redirect_to collection, notice: "Storage unit was successfully deleted.", status: :see_other }
    end
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def set_storage_unit
    @storage_unit = StorageUnit.find(params[:id])
  end

  def storage_unit_params
    params.require(:storage_unit).permit(:name, :description, :storage_unit_type, :location, :parent_id)
  end
end
