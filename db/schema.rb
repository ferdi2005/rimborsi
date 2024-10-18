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

ActiveRecord::Schema[7.2].define(version: 2024_10_18_130700) do
  create_table "reimboursements", force: :cascade do |t|
    t.integer "state_id", null: false
    t.integer "user_id", null: false
    t.integer "bank_account_id", null: false
    t.integer "paypal_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_account_id"], name: "index_reimboursements_on_bank_account_id"
    t.index ["paypal_account_id"], name: "index_reimboursements_on_paypal_account_id"
    t.index ["state_id"], name: "index_reimboursements_on_state_id"
    t.index ["user_id"], name: "index_reimboursements_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
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
    t.integer "telephone"
    t.string "username"
    t.boolean "admin"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "reimboursements", "bank_accounts"
  add_foreign_key "reimboursements", "paypal_accounts"
  add_foreign_key "reimboursements", "states"
  add_foreign_key "reimboursements", "users"
end
