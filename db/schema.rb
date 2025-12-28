# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_28_063156) do
  create_table "catalogs", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.json "source_config", default: {}, null: false
    t.string "source_type", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type"], name: "index_catalogs_on_source_type"
  end

  create_table "mtg_cards", id: :string, force: :cascade do |t|
    t.datetime "cached_at"
    t.string "collector_number", null: false
    t.json "color_identity", default: []
    t.json "colors", default: []
    t.datetime "created_at", null: false
    t.json "finishes", default: []
    t.json "frame_effects", default: []
    t.string "mana_cost"
    t.decimal "mana_value", precision: 10, scale: 2
    t.string "mtg_set_id", null: false
    t.string "name", null: false
    t.text "oracle_text"
    t.string "power"
    t.json "prices", default: {}
    t.json "promo_types", default: []
    t.string "rarity"
    t.string "scryfall_id"
    t.string "set_code", null: false
    t.json "source_data", default: {}
    t.string "toughness"
    t.string "type_line"
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["mtg_set_id"], name: "index_mtg_cards_on_mtg_set_id"
    t.index ["name"], name: "index_mtg_cards_on_name"
    t.index ["scryfall_id"], name: "index_mtg_cards_on_scryfall_id", unique: true
    t.index ["set_code", "collector_number"], name: "index_mtg_cards_on_set_code_and_collector_number", unique: true
    t.index ["uuid"], name: "index_mtg_cards_on_uuid", unique: true
  end

  create_table "mtg_sets", id: :string, force: :cascade do |t|
    t.integer "card_count"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "icon_uri"
    t.string "name", null: false
    t.date "release_date"
    t.string "set_type"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_mtg_sets_on_code", unique: true
  end

  add_foreign_key "mtg_cards", "mtg_sets"
end
