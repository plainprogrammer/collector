class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :storage_unit, null: true, foreign_key: true
      t.string :card_uuid, null: false

      # Variant identification
      t.integer :finish, null: false
      t.string :language, limit: 2, null: false, default: "en"
      t.integer :condition, null: false

      # Special attributes
      t.boolean :signed, default: false, null: false
      t.boolean :altered, default: false, null: false
      t.boolean :misprint, default: false, null: false

      # Grading
      t.string :grading_service
      t.decimal :grading_score, precision: 3, scale: 1

      # Acquisition
      t.date :acquisition_date
      t.decimal :acquisition_price, precision: 10, scale: 2

      # Notes
      t.text :notes

      t.timestamps
    end

    add_index :items, :card_uuid
    add_index :items, [ :collection_id, :card_uuid ]
  end
end
