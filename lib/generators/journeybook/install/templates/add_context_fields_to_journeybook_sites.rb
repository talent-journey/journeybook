class AddContextFieldsToJourneybookSites < ActiveRecord::Migration[8.0]
  def change
    remove_index :journeybook_sites, :host if index_exists?(:journeybook_sites, :host, unique: true)

    add_column :journeybook_sites, :key, :string
    add_column :journeybook_sites, :path_prefix, :string, null: false, default: "/"
    add_column :journeybook_sites, :layout, :string

    reversible do |dir|
      dir.up do
        say_with_time "Backfilling Journeybook site keys" do
          site_class = Class.new(ActiveRecord::Base) do
            self.table_name = "journeybook_sites"
          end

          used_keys = {}
          site_class.order(:id).find_each do |site|
            base_key = site.name.to_s.parameterize(separator: "_").presence || "site"
            key = base_key
            suffix = 2

            while used_keys.key?(key)
              key = "#{base_key}_#{suffix}"
              suffix += 1
            end

            used_keys[key] = true
            site.update_columns(key: key)
          end
        end
      end
    end

    add_index :journeybook_sites, :key, unique: true
    add_index :journeybook_sites, :host
    add_index :journeybook_sites, %i[host path_prefix], unique: true
  end
end
