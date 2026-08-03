class CreateJourneybookMediaAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :journeybook_media_assets do |t|
      t.string :title, null: false
      t.string :alt_text
      t.text :description
      t.string :tags
      t.string :storage_key, null: false
      t.string :original_filename, null: false
      t.string :content_type, null: false
      t.integer :byte_size, null: false
      t.string :checksum
      t.integer :width
      t.integer :height
      t.json :metadata

      t.timestamps
    end

    add_index :journeybook_media_assets, :storage_key, unique: true
    add_index :journeybook_media_assets, :title
    add_index :journeybook_media_assets, :content_type
  end
end
