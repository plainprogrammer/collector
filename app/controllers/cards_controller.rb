class CardsController < ApplicationController
  def index
    if search_params_present?
      @pagy, @cards = search_cards
    else
      @cards = MTGJSON::Card.none
      @show_prompt = true
    end
  end

  def show
    @card = MTGJSON::Card.includes(:set, :identifiers, :legalities, :rulings)
                         .find_by!(uuid: params[:uuid])
    @other_printings = find_other_printings(@card)
  rescue ActiveRecord::RecordNotFound
    redirect_to cards_path, alert: "Card not found"
  end

  private

  def search_params_present?
    params[:name].present? || params[:set_code].present?
  end

  def search_cards
    cards = MTGJSON::Card.includes(:set)
    cards = cards.by_name(params[:name]) if params[:name].present?
    cards = cards.by_set(params[:set_code].upcase) if params[:set_code].present?

    pagy(:offset, cards.order(:name, :setCode), limit: 50)
  end

  def find_other_printings(card)
    MTGJSON::Card.includes(:set)
                 .where(name: card.name)
                 .where.not(uuid: card.uuid)
                 .joins(:set)
                 .order("sets.releaseDate DESC")
                 .limit(20)
  end
end
