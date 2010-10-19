# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100701170542) do

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.text     "url"
    t.string   "document_id"
    t.string   "title"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_blocks", :force => true do |t|
    t.string   "title",      :null => false
    t.integer  "user_id",    :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_blocks", ["title"], :name => "index_content_blocks_on_title"

  create_table "reports", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "category",     :null => false
    t.datetime "generated_on"
    t.integer  "user_id"
    t.text     "options"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reports", ["category"], :name => "index_reports_on_category"

  create_table "searches", :force => true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], :name => "index_searches_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "login",             :null => false
    t.string   "email"
    t.string   "crypted_password"
    t.text     "last_search_url"
    t.datetime "last_login_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "current_login_at"
  end

end