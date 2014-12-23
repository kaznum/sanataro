# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141223142546) do

  create_table "accounts", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.boolean  "active",     limit: 1,   default: true
    t.string   "type",       limit: 255
    t.integer  "order_no",   limit: 4
    t.datetime "updated_at"
    t.string   "bgcolor",    limit: 255
  end

  create_table "autologin_keys", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.string   "enc_autologin_key", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "credit_relations", force: :cascade do |t|
    t.integer  "credit_account_id",  limit: 4
    t.integer  "payment_account_id", limit: 4
    t.integer  "settlement_day",     limit: 4
    t.integer  "payment_month",      limit: 4
    t.integer  "payment_day",        limit: 4
    t.integer  "user_id",            limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", force: :cascade do |t|
    t.integer  "user_id",               limit: 4,                   null: false
    t.string   "name",                  limit: 255
    t.integer  "from_account_id",       limit: 4
    t.integer  "to_account_id",         limit: 4
    t.string   "currency",              limit: 255
    t.integer  "amount",                limit: 4
    t.date     "action_date"
    t.datetime "created_at"
    t.integer  "adjustment_amount",     limit: 4,   default: 0
    t.integer  "parent_id",             limit: 4
    t.datetime "updated_at"
    t.boolean  "confirmation_required", limit: 1,   default: false
    t.string   "type",                  limit: 255
  end

  create_table "monthly_profit_losses", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.date     "month"
    t.integer  "account_id", limit: 4
    t.integer  "amount",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4,   null: false
    t.integer  "application_id",    limit: 4,   null: false
    t.string   "token",             limit: 255, null: false
    t.integer  "expires_in",        limit: 4,   null: false
    t.string   "redirect_uri",      limit: 255, null: false
    t.datetime "created_at",                    null: false
    t.datetime "revoked_at"
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4
    t.integer  "application_id",    limit: 4,   null: false
    t.string   "token",             limit: 255, null: false
    t.string   "refresh_token",     limit: 255
    t.integer  "expires_in",        limit: 4
    t.datetime "revoked_at"
    t.datetime "created_at",                    null: false
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         limit: 255,              null: false
    t.string   "uid",          limit: 255,              null: false
    t.string   "secret",       limit: 255,              null: false
    t.string   "redirect_uri", limit: 255,              null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "scopes",       limit: 255, default: "", null: false
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id",        limit: 4
    t.integer "taggable_id",   limit: 4
    t.string  "taggable_type", limit: 255
    t.integer "user_id",       limit: 4
  end

  add_index "taggings", ["tag_id", "taggable_type"], name: "index_taggings_on_tag_id_and_taggable_type", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type", using: :btree
  add_index "taggings", ["user_id", "tag_id", "taggable_type"], name: "index_taggings_on_user_id_and_tag_id_and_taggable_type", using: :btree
  add_index "taggings", ["user_id", "taggable_id", "taggable_type"], name: "index_taggings_on_user_id_and_taggable_id_and_taggable_type", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count", limit: 4,   default: 0, null: false
  end

  add_index "tags", ["name"], name: "index_tags_on_name", using: :btree
  add_index "tags", ["taggings_count"], name: "index_tags_on_taggings_count", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "login",        limit: 255
    t.string   "password",     limit: 255
    t.datetime "created_at"
    t.boolean  "active",       limit: 1,   default: true
    t.datetime "updated_at"
    t.string   "email",        limit: 255
    t.string   "confirmation", limit: 255
  end

end
