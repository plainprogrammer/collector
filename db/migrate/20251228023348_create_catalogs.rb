class CreateCatalogs < ActiveRecord::Migration[8.1]
  def change
    create_table :catalogs, id: :string do |t|
      t.string :name, null: false
      t.string :source_type, null: false
      t.json :source_config, null: false, default: {}

      t.timestamps
    end

    add_index :catalogs, :source_type
  end
end
