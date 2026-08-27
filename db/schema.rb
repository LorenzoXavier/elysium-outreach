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

ActiveRecord::Schema[8.1].define(version: 2026_08_17_151006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "contacts", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "duplicate_status", default: "unique", null: false
    t.string "email"
    t.text "email_body"
    t.datetime "email_followup_due_at"
    t.string "email_status", default: "pending", null: false
    t.string "first_name"
    t.string "full_name"
    t.string "import_batch_id"
    t.string "last_name"
    t.datetime "linkedin_outreached_at"
    t.string "linkedin_url"
    t.string "location"
    t.bigint "matched_contact_id"
    t.text "notes"
    t.string "phone"
    t.string "priority_status", default: "amber", null: false
    t.string "source"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["duplicate_status"], name: "index_contacts_on_duplicate_status"
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["full_name", "company"], name: "index_contacts_on_full_name_and_company"
    t.index ["import_batch_id"], name: "index_contacts_on_import_batch_id"
    t.index ["linkedin_url"], name: "index_contacts_on_linkedin_url"
    t.index ["matched_contact_id"], name: "index_contacts_on_matched_contact_id"
    t.index ["priority_status"], name: "index_contacts_on_priority_status"
  end

  add_foreign_key "contacts", "contacts", column: "matched_contact_id"
end
