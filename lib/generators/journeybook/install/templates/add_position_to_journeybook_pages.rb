class AddPositionToJourneybookPages < ActiveRecord::Migration[8.0]
  def change
    add_column :journeybook_pages, :position, :integer, null: false, default: 0
    add_index :journeybook_pages, %i[site_id page_type parent_id position]
  end
end
