class AddOpenInNewWindowToJourneybookNavigationItems < ActiveRecord::Migration[8.0]
  def change
    add_column :journeybook_navigation_items, :open_in_new_window, :boolean, default: false, null: false
  end
end
