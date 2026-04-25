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

ActiveRecord::Schema[7.2].define(version: 2026_04_25_081557) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "integrations", force: :cascade do |t|
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.string "webhook_url"
    t.string "api_endpoint", null: false
    t.string "api_key"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "webhook_secret", null: false
    t.index ["status"], name: "index_integrations_on_status"
    t.index ["user_id", "name"], name: "index_integrations_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_integrations_on_user_id"
    t.index ["webhook_secret"], name: "index_integrations_on_webhook_secret", unique: true
  end

  create_table "sync_logs", force: :cascade do |t|
    t.bigint "integration_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.integer "response_code"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_sync_logs_on_created_at"
    t.index ["event_type"], name: "index_sync_logs_on_event_type"
    t.index ["integration_id"], name: "index_sync_logs_on_integration_id"
    t.index ["status"], name: "index_sync_logs_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.bigint "integration_id", null: false
    t.string "event_type"
    t.jsonb "payload", default: {}, null: false
    t.boolean "processed", default: false, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_webhook_events_on_created_at"
    t.index ["event_type"], name: "index_webhook_events_on_event_type"
    t.index ["integration_id"], name: "index_webhook_events_on_integration_id"
    t.index ["processed"], name: "index_webhook_events_on_processed"
  end

  add_foreign_key "integrations", "users"
  add_foreign_key "sync_logs", "integrations"
  add_foreign_key "webhook_events", "integrations"
end
