class CreateJourneybookNavigation < ActiveRecord::Migration[8.0]
  def change
    create_table :journeybook_navigation_menus do |t|
      t.references :site, null: false, foreign_key: { to_table: :journeybook_sites }
      t.string :key, null: false
      t.string :title, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :journeybook_navigation_menus, %i[site_id key], unique: true

    create_table :journeybook_navigation_items do |t|
      t.references :navigation_menu, null: false, foreign_key: { to_table: :journeybook_navigation_menus }
      t.references :page, foreign_key: { to_table: :journeybook_pages }
      t.string :label, null: false
      t.text :description
      t.string :external_url
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true

      t.timestamps
    end

    add_index :journeybook_navigation_items, %i[navigation_menu_id position]
  end
end
