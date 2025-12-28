class CreateMTGSets < ActiveRecord::Migration[8.1]
  def change
    create_table :mtg_sets, id: :string do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.date :release_date
      t.string :set_type
      t.integer :card_count
      t.string :icon_uri

      t.timestamps
    end

    add_index :mtg_sets, :code, unique: true
  end
end
