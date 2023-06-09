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

ActiveRecord::Schema.define(version: 2023_05_22_032251) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "timescaledb"

  create_table "categories", force: :cascade do |t|
    t.string "name"
  end

  create_table "comments", force: :cascade do |t|
    t.text "comment"
    t.integer "user_id"
    t.integer "post_id"
    t.datetime "created_at"
  end

  create_table "likes", force: :cascade do |t|
    t.integer "user_id"
    t.integer "post_id"
  end

  create_table "nouns", force: :cascade do |t|
    t.string "name"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.integer "noun_id"
    t.integer "verb_id"
    t.text "context"
    t.text "question"
    t.integer "category_id"
    t.boolean "is_open"
    t.integer "user_id"
    t.datetime "created_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.string "img"
    t.datetime "created_at"
  end

  create_table "verbs", force: :cascade do |t|
    t.string "name"
  end

  add_foreign_key "comments", "users", on_delete: :cascade
  add_foreign_key "likes", "posts", on_delete: :cascade
  add_foreign_key "likes", "users", on_delete: :cascade
end
