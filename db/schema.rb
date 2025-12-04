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

ActiveRecord::Schema[7.1].define(version: 2025_12_04_191235) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "habits", force: :cascade do |t|
    t.string "habit_name"
    t.string "emoji"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "completed_on"
    t.text "description"
    t.index ["user_id"], name: "index_habits_on_user_id"
  end

  create_table "streakling_creatures", force: :cascade do |t|
    t.bigint "habit_id", null: false
    t.string "streakling_name", default: "Little One"
    t.string "animal_type", default: "dragon"
    t.integer "current_streak", default: 0
    t.integer "longest_streak", default: 0
    t.string "mood", default: "happy"
    t.integer "consecutive_missed_days", default: 0
    t.boolean "is_dead", default: false
    t.date "died_at"
    t.integer "revived_count", default: 0
    t.string "stage", default: "egg"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["habit_id"], name: "index_streakling_creatures_on_habit_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_streak"
    t.integer "longest_streak"
    t.date "last_completed_date"
    t.integer "daily_points"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "habits", "users"
  add_foreign_key "streakling_creatures", "habits"
end
