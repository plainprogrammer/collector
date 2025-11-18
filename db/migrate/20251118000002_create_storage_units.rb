class CreateStorageUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :storage_units do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :storage_units }, null: true
      t.integer :storage_unit_type, null: false
      t.string :name, null: false
      t.text :description
      t.string :location

      t.timestamps
    end

    add_index :storage_units, :storage_unit_type
  end
end
