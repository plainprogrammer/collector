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

ActiveRecord::Schema[8.1].define(version: 2025_12_28_062826) do
  create_table "catalogs", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.json "source_config", default: {}, null: false
    t.string "source_type", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type"], name: "index_catalogs_on_source_type"
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
end
