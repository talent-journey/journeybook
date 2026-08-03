# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_01_000011) do
  create_table "journeybook_ai_style_prompts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "prompt", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_journeybook_ai_style_prompts_on_name", unique: true
  end

  create_table "journeybook_media_assets", force: :cascade do |t|
    t.string "alt_text"
    t.integer "byte_size", null: false
    t.string "checksum"
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "height"
    t.json "metadata"
    t.string "original_filename", null: false
    t.string "storage_key", null: false
    t.string "tags"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "width"
    t.index ["content_type"], name: "index_journeybook_media_assets_on_content_type"
    t.index ["storage_key"], name: "index_journeybook_media_assets_on_storage_key", unique: true
    t.index ["title"], name: "index_journeybook_media_assets_on_title"
  end

  create_table "journeybook_navigation_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "external_url"
    t.string "label", null: false
    t.integer "navigation_menu_id", null: false
    t.boolean "open_in_new_window", default: false, null: false
    t.integer "page_id"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["navigation_menu_id", "position"], name: "idx_on_navigation_menu_id_position_638f8e9064"
    t.index ["navigation_menu_id"], name: "index_journeybook_navigation_items_on_navigation_menu_id"
    t.index ["page_id"], name: "index_journeybook_navigation_items_on_page_id"
  end

  create_table "journeybook_navigation_menus", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.integer "position", default: 0, null: false
    t.integer "site_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "key"], name: "index_journeybook_navigation_menus_on_site_id_and_key", unique: true
    t.index ["site_id"], name: "index_journeybook_navigation_menus_on_site_id"
  end

  create_table "journeybook_pages", force: :cascade do |t|
    t.string "author_name"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.string "layout"
    t.string "locale", default: "en", null: false
    t.text "markdown", null: false
    t.text "meta_description"
    t.string "meta_title"
    t.string "page_type", default: "page", null: false
    t.integer "parent_id"
    t.string "path", null: false
    t.integer "position", default: 0, null: false
    t.datetime "published_at"
    t.integer "site_id", null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.string "topic"
    t.datetime "updated_at", null: false
    t.index ["page_type"], name: "index_journeybook_pages_on_page_type"
    t.index ["parent_id"], name: "index_journeybook_pages_on_parent_id"
    t.index ["site_id", "locale", "path"], name: "index_journeybook_pages_on_site_id_and_locale_and_path", unique: true
    t.index ["site_id", "locale", "slug"], name: "index_journeybook_pages_on_site_id_and_locale_and_slug", unique: true
    t.index ["site_id", "page_type", "parent_id", "position"], name: "idx_on_site_id_page_type_parent_id_position_2650ca9734"
    t.index ["site_id", "page_type", "topic"], name: "index_journeybook_pages_on_site_id_and_page_type_and_topic"
    t.index ["site_id"], name: "index_journeybook_pages_on_site_id"
    t.index ["status"], name: "index_journeybook_pages_on_status"
  end

  create_table "journeybook_redirects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "from", null: false
    t.integer "status_code", default: 301, null: false
    t.string "to", null: false
    t.datetime "updated_at", null: false
    t.index ["from"], name: "index_journeybook_redirects_on_from", unique: true
  end

  create_table "journeybook_sites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_locale", default: "en", null: false
    t.string "host", null: false
    t.string "key"
    t.string "layout"
    t.string "name", null: false
    t.string "path_prefix", default: "/", null: false
    t.datetime "updated_at", null: false
    t.index ["host", "path_prefix"], name: "index_journeybook_sites_on_host_and_path_prefix", unique: true
    t.index ["host"], name: "index_journeybook_sites_on_host"
    t.index ["key"], name: "index_journeybook_sites_on_key", unique: true
  end

  add_foreign_key "journeybook_navigation_items", "journeybook_navigation_menus", column: "navigation_menu_id"
  add_foreign_key "journeybook_navigation_items", "journeybook_pages", column: "page_id"
  add_foreign_key "journeybook_navigation_menus", "journeybook_sites", column: "site_id"
  add_foreign_key "journeybook_pages", "journeybook_pages", column: "parent_id"
  add_foreign_key "journeybook_pages", "journeybook_sites", column: "site_id"
end
