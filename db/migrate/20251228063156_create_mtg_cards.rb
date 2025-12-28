class CreateMTGCards < ActiveRecord::Migration[8.1]
  def change
    create_table :mtg_cards, id: :string do |t|
      t.string :mtg_set_id, null: false
      t.string :uuid, null: false
      t.string :scryfall_id
      t.string :name, null: false
      t.string :set_code, null: false
      t.string :collector_number, null: false
      t.string :rarity
      t.string :mana_cost
      t.decimal :mana_value, precision: 10, scale: 2
      t.string :type_line
      t.text :oracle_text
      t.string :power
      t.string :toughness
      t.json :colors, default: []
      t.json :color_identity, default: []
      t.json :finishes, default: []
      t.json :frame_effects, default: []
      t.json :promo_types, default: []
      t.json :prices, default: {}
      t.json :source_data, default: {}
      t.datetime :cached_at

      t.timestamps
    end

    add_index :mtg_cards, :mtg_set_id
    add_index :mtg_cards, :uuid, unique: true
    add_index :mtg_cards, :scryfall_id, unique: true
    add_index :mtg_cards, :name
    add_index :mtg_cards, [ :set_code, :collector_number ], unique: true

    add_foreign_key :mtg_cards, :mtg_sets
  end
end
