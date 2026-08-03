class CreateJourneybookRedirects < ActiveRecord::Migration[8.0]
  def change
    create_table :journeybook_redirects do |t|
      t.string :from, null: false
      t.string :to, null: false
      t.integer :status_code, null: false, default: 301

      t.timestamps
    end

    add_index :journeybook_redirects, :from, unique: true
  end
end
