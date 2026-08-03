class CreateJourneybookPages < ActiveRecord::Migration[8.0]
  def change
    create_table :journeybook_pages do |t|
      t.references :site, null: false, foreign_key: { to_table: :journeybook_sites }
      t.string :title, null: false
      t.string :slug, null: false
      t.string :path, null: false
      t.text :markdown, null: false
      t.string :meta_title
      t.text :meta_description
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.string :layout
      t.string :locale, null: false, default: "en"

      t.timestamps
    end

    add_index :journeybook_pages, %i[site_id locale slug], unique: true
    add_index :journeybook_pages, %i[site_id locale path], unique: true
    add_index :journeybook_pages, :status
  end
end
