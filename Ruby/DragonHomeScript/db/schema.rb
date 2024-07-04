# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_10_07_203934) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.bigint "activity_type_id"
    t.bigint "user_id"
    t.datetime "tstart", null: false
    t.datetime "tend"
    t.string "description"
    t.jsonb "extra_flags"
    t.index ["activity_type_id"], name: "index_activities_on_activity_type_id"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "activity_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "category"
    t.string "color"
  end

  create_table "user_locations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "ts", null: false
    t.float "lat", null: false
    t.float "lon", null: false
    t.float "velocity"
    t.float "elevation"
    t.index ["user_id"], name: "index_user_locations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "hook_config"
  end

end
