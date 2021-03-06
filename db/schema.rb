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

ActiveRecord::Schema.define(version: 2020_10_16_140842) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "tweets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "tweet_id", null: false
    t.jsonb "tweet", default: "{}", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "meta"
    t.datetime "tweet_date"
    t.index ["tweet_id", "user_id"], name: "index_tweets_on_tweet_id_and_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "secret_key", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "data", default: {}
    t.text "encrypted_data", default: ""
    t.string "screen_name", default: ""
    t.jsonb "cookie_keys", default: []
    t.string "email", default: ""
  end

end
