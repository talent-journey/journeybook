class AddBlogFieldsToJourneybookPages < ActiveRecord::Migration[8.0]
  def change
    add_column :journeybook_pages, :page_type, :string, null: false, default: "page"
    add_column :journeybook_pages, :excerpt, :text
    add_column :journeybook_pages, :author_name, :string

    add_index :journeybook_pages, :page_type
  end
end
