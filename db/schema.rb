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

ActiveRecord::Schema[7.2].define(version: 2025_10_14_134818) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "iban"
    t.string "owner"
    t.string "address"
    t.string "cap"
    t.string "town"
    t.string "fiscal_code"
    t.boolean "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bank_name"
    t.string "bic_swift"
    t.index ["user_id"], name: "index_bank_accounts_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "reimboursement_id", null: false
    t.text "purpose"
    t.date "date"
    t.decimal "amount", precision: 8, scale: 2
    t.boolean "car", default: false
    t.date "calculation_date"
    t.string "departure"
    t.string "arrival"
    t.integer "distance"
    t.boolean "return_trip"
    t.decimal "quota_capitale"
    t.decimal "carburante"
    t.decimal "pneumatici"
    t.decimal "manutenzione"
    t.bigint "fund_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "vehicle_id"
    t.string "project"
    t.decimal "requested_amount", precision: 8, scale: 2
    t.index ["fund_id"], name: "index_expenses_on_fund_id"
    t.index ["reimboursement_id"], name: "index_expenses_on_reimboursement_id"
    t.index ["vehicle_id"], name: "index_expenses_on_vehicle_id"
  end

  create_table "funds", force: :cascade do |t|
    t.string "name"
    t.decimal "budget"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "reimboursement_id", null: false
    t.bigint "user_id", null: false
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status_change"
    t.index ["reimboursement_id"], name: "index_notes_on_reimboursement_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.date "payment_date"
    t.decimal "total", precision: 8, scale: 2
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "reimboursements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "bank_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.bigint "payment_id"
    t.index ["bank_account_id"], name: "index_reimboursements_on_bank_account_id"
    t.index ["payment_id"], name: "index_reimboursements_on_payment_id"
    t.index ["user_id"], name: "index_reimboursements_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "states", force: :cascade do |t|
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "surname"
    t.string "telephone"
    t.boolean "admin"
    t.bigint "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.boolean "active", default: true, null: false
    t.string "fiscal_code"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "name"
    t.integer "vehicle_category"
    t.integer "fuel_type"
    t.string "brand"
    t.string "model"
    t.boolean "default"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_vehicles_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bank_accounts", "users"
  add_foreign_key "expenses", "funds"
  add_foreign_key "expenses", "reimboursements"
  add_foreign_key "notes", "reimboursements"
  add_foreign_key "notes", "users"
  add_foreign_key "reimboursements", "bank_accounts"
  add_foreign_key "reimboursements", "payments"
  add_foreign_key "reimboursements", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "vehicles", "users"
end
