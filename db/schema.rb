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

ActiveRecord::Schema.define(version: 20141117152913) do

  create_table "blockades", force: true do |t|
    t.integer  "blocker_id"
    t.integer  "blocked_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "code_requests", force: true do |t|
    t.string   "phone_number"
    t.integer  "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "future_messages", force: true do |t|
    t.integer  "sender_id"
    t.string   "receiver_number"
    t.integer  "future_record_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "text_sent",        default: false
    t.boolean  "converted"
  end

  add_index "future_messages", ["receiver_number"], name: "index_future_messages_on_receiver_number", using: :btree

  create_table "future_records", force: true do |t|
    t.string   "recording_file_name"
    t.string   "recording_content_type"
    t.integer  "recording_file_size"
    t.datetime "recording_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_memberships", force: true do |t|
    t.integer "user_id"
    t.integer "group_id"
  end

  create_table "groups", force: true do |t|
    t.string   "name"
    t.integer  "members_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invited_numbers", force: true do |t|
    t.string   "phone_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mapped_contacts", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", force: true do |t|
    t.integer  "sender_id"
    t.integer  "receiver_id"
    t.integer  "group_id"
    t.boolean  "opened"
    t.string   "record_file_name"
    t.string   "record_content_type"
    t.integer  "record_file_size"
    t.datetime "record_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "future",              default: false
    t.integer  "creation_date",       default: 0
  end

  create_table "prospects", force: true do |t|
    t.string   "phone_number"
    t.integer  "contacts_count"
    t.string   "contact_ids"
    t.string   "facebook_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prospects", ["phone_number"], name: "index_prospects_on_phone_number", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "phone_number"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "app_version"
    t.string   "api_version"
    t.string   "push_token"
    t.string   "auth_token"
    t.string   "profile_picture_file_name"
    t.string   "profile_picture_content_type"
    t.integer  "profile_picture_file_size"
    t.datetime "profile_picture_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "retrieve_contacts",            default: false
    t.boolean  "contact_auth",                 default: false
    t.boolean  "micro_auth"
    t.boolean  "push_auth"
    t.string   "os_version"
    t.integer  "futures"
    t.integer  "favorites"
    t.integer  "nb_contacts"
    t.integer  "nb_contacts_users"
    t.integer  "nb_contacts_photos"
    t.integer  "nb_contacts_favorites"
    t.integer  "nb_contacts_facebook"
    t.integer  "nb_contacts_photo_only"
    t.integer  "nb_contacts_family"
    t.integer  "nb_contacts_related"
    t.integer  "nb_contacts_linked"
    t.string   "fb_id"
    t.string   "fb_first_name"
    t.string   "fb_last_name"
    t.string   "fb_gender"
    t.string   "fb_locale"
    t.string   "email"
    t.integer  "initial_messages_nb"
    t.integer  "text_received_nb"
  end

end
