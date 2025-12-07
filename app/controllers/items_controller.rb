class ItemsController < ApplicationController
  include Pagy::Method

  before_action :set_collection, only: [ :index, :new, :create ]
  before_action :set_item, only: [ :show, :edit, :update, :destroy, :move, :relocate ]
  before_action :set_card, only: [ :new, :create ]

  def index
    # Load all cards for items in this collection (needed for filtering)
    all_item_uuids = @collection.items.pluck(:card_uuid).uniq
    @all_cards = MTGJSON::Card.includes(:set, :identifiers)
                              .where(uuid: all_item_uuids)
                              .index_by(&:uuid)

    # Build filters
    @filters = ItemFilters.new(filter_params)
    @applied_filters = @filters.to_h

    # Start with base query
    items = @collection.items.includes(:storage_unit)

    # Apply filters
    items = @filters.apply(items, cards: @all_cards)

    # Apply sorting
    items = apply_sort(items, @all_cards)

    # Paginate
    @pagy, @items = pagy(items)

    # Build cards hash for just the paginated items
    @cards = @all_cards.slice(*@items.map(&:card_uuid))

    # Get available sets for filter dropdown
    @available_sets = @all_cards.values.map(&:setCode).uniq.compact.sort

    respond_to do |format|
      format.html
      format.turbo_stream if turbo_frame_request?
    end
  end

  def show
    @card = @item.card
  end

  def new
    @item = @collection.items.build(
      card_uuid: @card.uuid,
      condition: :near_mint,
      finish: :nonfoil,
      language: "en"
    )
    @storage_units = @collection.storage_units.order(:name)
  end

  def create
    @item = @collection.items.build(item_params)
    @item.card_uuid = @card.uuid

    if @item.save
      redirect_to collection_items_path(@collection),
                  notice: "#{@card.name} added to #{@collection.name}"
    else
      @storage_units = @collection.storage_units.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @card = @item.card
    @storage_units = @item.collection.storage_units.order(:name)
  end

  def update
    if @item.update(item_params)
      redirect_to @item, notice: "Item updated successfully"
    else
      @card = @item.card
      @storage_units = @item.collection.storage_units.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    collection = @item.collection
    card_name = @item.card&.name || "Item"

    @item.destroy!

    redirect_to collection_items_path(collection),
                notice: "#{card_name} removed from collection"
  end

  def move
    @card = @item.card
    @collections = Collection.order(:name)
    @storage_units = @item.collection.storage_units.order(:name)
  end

  def relocate
    new_collection = Collection.find(relocate_params[:collection_id])
    new_storage_unit = nil

    if relocate_params[:storage_unit_id].present?
      new_storage_unit = new_collection.storage_units.find(relocate_params[:storage_unit_id])
    end

    @item.move_to_collection!(new_collection, new_storage_unit: new_storage_unit)

    redirect_to @item, notice: "Item moved to #{new_collection.name}"
  rescue ActiveRecord::RecordInvalid => e
    @card = @item.card
    @collections = Collection.order(:name)
    @storage_units = @item.collection.storage_units.order(:name)
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :move, status: :unprocessable_entity
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def set_item
    @item = Item.includes(:collection, :storage_unit).find(params[:id])
  end

  def set_card
    @card = MTGJSON::Card.includes(:set, :identifiers)
                         .find_by!(uuid: params[:card_uuid])
  rescue ActiveRecord::RecordNotFound
    redirect_to cards_path, alert: "Card not found"
  end

  def item_params
    params.require(:item).permit(
      :storage_unit_id,
      :condition,
      :finish,
      :language,
      :signed,
      :altered,
      :misprint,
      :acquisition_date,
      :acquisition_price,
      :grading_service,
      :grading_score,
      :notes
    )
  end

  def relocate_params
    params.require(:item).permit(:collection_id, :storage_unit_id)
  end

  def load_cards_for_items(items)
    uuids = items.map(&:card_uuid).uniq
    MTGJSON::Card.includes(:set, :identifiers)
                 .where(uuid: uuids)
                 .index_by(&:uuid)
  end

  def filter_params
    params.permit(:set, :color, :type, :condition, :finish, :sort)
  end

  def apply_sort(items, cards)
    case params[:sort]
    when "name_asc"
      sort_by_card_name(items, cards, :asc)
    when "name_desc"
      sort_by_card_name(items, cards, :desc)
    when "date_asc"
      items.order(created_at: :asc)
    when "condition_asc"
      items.order(condition: :asc)
    when "condition_desc"
      items.order(condition: :desc)
    else # "date_desc" or default
      items.order(created_at: :desc)
    end
  end

  def sort_by_card_name(items, cards, direction)
    # For name sorting, we need to do it in-memory since card data is in a different database
    item_ids = items.pluck(:id)
    items_with_names = Item.where(id: item_ids).map do |item|
      card = cards[item.card_uuid]
      [ item.id, card&.name || "" ]
    end

    sorted_ids = if direction == :asc
      items_with_names.sort_by { |_, name| name.downcase }.map(&:first)
    else
      items_with_names.sort_by { |_, name| name.downcase }.reverse.map(&:first)
    end

    # Return items ordered by the sorted IDs
    Item.where(id: sorted_ids).includes(:storage_unit).order(
      Arel.sql("CASE #{sorted_ids.each_with_index.map { |id, i| "WHEN items.id = #{id} THEN #{i}" }.join(" ")} END")
    )
  end
end
