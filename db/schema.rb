# frozen_string_literal: true

# Database schema for TaskFlow API
# This file is auto-generated from the current state of the database

ActiveRecord::Schema[7.1].define(version: 2024_01_01_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "refresh_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["refresh_token"], name: "index_users_on_refresh_token"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "status", null: false, default: 0
    t.integer "priority", null: false, default: 1
    t.date "due_date"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_tasks_on_user_id_and_status"
    t.index ["priority"], name: "index_tasks_on_priority"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["user_id"], name: "index_tasks_on_user_id"
    t.foreign_key "users"
  end
end
