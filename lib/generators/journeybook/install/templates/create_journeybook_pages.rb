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

      t.string :page_type, null: false, default: "page"
      t.text :excerpt
      t.string :author_name
      t.references :parent, foreign_key: { to_table: :journeybook_pages }
      t.string :topic
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :journeybook_pages, %i[site_id locale slug], unique: true
    add_index :journeybook_pages, %i[site_id locale path], unique: true
    add_index :journeybook_pages, :status
    add_index :journeybook_pages, :page_type
    add_index :journeybook_pages, %i[site_id page_type topic]
    add_index :journeybook_pages, %i[site_id page_type parent_id position]
  end
end
