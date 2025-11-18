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

ActiveRecord::Schema[8.1].define(version: 2025_11_18_000002) do
  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "storage_units", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "location"
    t.string "name", null: false
    t.integer "parent_id"
    t.integer "storage_unit_type", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_storage_units_on_collection_id"
    t.index ["parent_id"], name: "index_storage_units_on_parent_id"
    t.index ["storage_unit_type"], name: "index_storage_units_on_storage_unit_type"
  end

  add_foreign_key "storage_units", "collections"
  add_foreign_key "storage_units", "storage_units", column: "parent_id"
end
