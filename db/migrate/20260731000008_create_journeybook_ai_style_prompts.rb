class CreateJourneybookAiStylePrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :journeybook_ai_style_prompts do |t|
      t.string :name, null: false
      t.text :prompt, null: false

      t.timestamps
    end

    add_index :journeybook_ai_style_prompts, :name, unique: true
  end
end
