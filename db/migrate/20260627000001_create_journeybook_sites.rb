class CreateJourneybookSites < ActiveRecord::Migration[8.0]
  def change
    create_table :journeybook_sites do |t|
      t.string :name, null: false
      t.string :host, null: false
      t.string :default_locale, null: false, default: "en"

      t.timestamps
    end

    add_index :journeybook_sites, :host, unique: true
  end
end
