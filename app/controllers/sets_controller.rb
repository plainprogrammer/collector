class SetsController < ApplicationController
  def index
    sets = MTGJSON::Set.released.order(releaseDate: :desc)
    sets = sets.by_type(params[:type]) if params[:type].present?
    @pagy, @sets = pagy(:offset, sets, limit: 24)

    @set_types = MTGJSON::Set.distinct.pluck(:type).compact.sort
  end

  def show
    @set = MTGJSON::Set.find_by!(code: params[:code])
    @pagy, @cards = pagy(:offset, @set.cards.order(:number, :name), limit: 50)
  rescue ActiveRecord::RecordNotFound
    redirect_to sets_path, alert: "Set not found"
  end
end
