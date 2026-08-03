class AddKnowledgeBaseFieldsToJourneybookPages < ActiveRecord::Migration[8.0]
  def change
    add_reference :journeybook_pages, :parent, foreign_key: { to_table: :journeybook_pages }
    add_column :journeybook_pages, :topic, :string

    add_index :journeybook_pages, %i[site_id page_type topic]
  end
end
