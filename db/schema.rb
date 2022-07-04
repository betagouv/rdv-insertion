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

ActiveRecord::Schema[7.0].define(version: 2022_07_01_155832) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "agents", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_agents_on_email", unique: true
  end

  create_table "agents_organisations", id: false, force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "agent_id", null: false
    t.index ["organisation_id", "agent_id"], name: "index_agents_organisations_on_organisation_id_and_agent_id", unique: true
  end

  create_table "applicants", force: :cascade do |t|
    t.string "uid"
    t.bigint "rdv_solidarites_user_id"
    t.string "affiliation_number"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "department_internal_id"
    t.string "first_name"
    t.string "last_name"
    t.string "address"
    t.string "phone_number"
    t.string "email"
    t.integer "title"
    t.date "birth_date"
    t.date "rights_opening_date"
    t.string "birth_name"
    t.bigint "department_id"
    t.string "archiving_reason"
    t.boolean "is_archived", default: false
    t.datetime "deleted_at"
    t.datetime "last_webhook_update_received_at"
    t.index ["department_id"], name: "index_applicants_on_department_id"
    t.index ["department_internal_id", "department_id"], name: "index_applicants_on_department_internal_id_and_department_id", unique: true
    t.index ["rdv_solidarites_user_id"], name: "index_applicants_on_rdv_solidarites_user_id", unique: true
    t.index ["uid"], name: "index_applicants_on_uid", unique: true
  end

  create_table "applicants_organisations", id: false, force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "applicant_id", null: false
    t.index ["organisation_id", "applicant_id"], name: "index_applicants_orgas_on_orga_id_and_applicant_id", unique: true
  end

  create_table "applicants_rdvs", id: false, force: :cascade do |t|
    t.bigint "applicant_id", null: false
    t.bigint "rdv_id", null: false
    t.index ["applicant_id", "rdv_id"], name: "index_applicants_rdvs_on_applicant_id_and_rdv_id", unique: true
  end

  create_table "configurations", force: :cascade do |t|
    t.string "sheet_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "column_names"
    t.string "invitation_formats", default: ["sms", "email", "postal"], null: false, array: true
    t.boolean "notify_applicant", default: false
    t.integer "motif_category", default: 0
    t.integer "number_of_days_to_accept_invitation", default: 3
    t.integer "number_of_days_before_action_required", default: 10
    t.string "signature_lines", array: true
  end

  create_table "configurations_organisations", id: false, force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "configuration_id", null: false
    t.index ["organisation_id", "configuration_id"], name: "index_config_orgas_on_organisation_id_and_configuration_id", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name"
    t.string "number"
    t.string "capital"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region"
    t.string "pronoun"
    t.string "email"
    t.string "phone_number"
  end

  create_table "invitation_parameters", force: :cascade do |t|
    t.string "direction_names", array: true
    t.string "sender_city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "letter_sender_name"
    t.string "sms_sender_name"
    t.string "signature_lines", array: true
    t.string "help_address"
    t.boolean "display_europe_logos", default: false
  end

  create_table "invitations", force: :cascade do |t|
    t.integer "format"
    t.string "link"
    t.string "token"
    t.datetime "sent_at", precision: nil
    t.bigint "applicant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "clicked", default: false
    t.string "help_phone_number"
    t.bigint "department_id"
    t.bigint "rdv_solidarites_lieu_id"
    t.bigint "rdv_context_id"
    t.integer "number_of_days_to_accept_invitation"
    t.datetime "valid_until"
    t.boolean "reminder", default: false
    t.index ["applicant_id"], name: "index_invitations_on_applicant_id"
    t.index ["department_id"], name: "index_invitations_on_department_id"
    t.index ["rdv_context_id"], name: "index_invitations_on_rdv_context_id"
  end

  create_table "invitations_organisations", id: false, force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "invitation_id", null: false
    t.index ["organisation_id", "invitation_id"], name: "index_invitations_orgas_on_orga_id_and_invitation_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "applicant_id", null: false
    t.integer "event"
    t.datetime "sent_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "rdv_solidarites_rdv_id"
    t.index ["applicant_id"], name: "index_notifications_on_applicant_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name"
    t.string "phone_number"
    t.string "email"
    t.bigint "rdv_solidarites_organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "department_id"
    t.bigint "invitation_parameters_id"
    t.datetime "last_webhook_update_received_at"
    t.string "slug"
    t.index ["department_id"], name: "index_organisations_on_department_id"
    t.index ["invitation_parameters_id"], name: "index_organisations_on_invitation_parameters_id"
    t.index ["rdv_solidarites_organisation_id"], name: "index_organisations_on_rdv_solidarites_organisation_id", unique: true
  end

  create_table "organisations_webhook_endpoints", id: false, force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "webhook_endpoint_id", null: false
    t.index ["organisation_id", "webhook_endpoint_id"], name: "index_webhook_orgas_on_orga_id_and_webhook_id", unique: true
  end

  create_table "rdv_contexts", force: :cascade do |t|
    t.integer "motif_category"
    t.integer "status"
    t.bigint "applicant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["applicant_id"], name: "index_rdv_contexts_on_applicant_id"
    t.index ["motif_category"], name: "index_rdv_contexts_on_motif_category"
    t.index ["status"], name: "index_rdv_contexts_on_status"
  end

  create_table "rdv_contexts_rdvs", id: false, force: :cascade do |t|
    t.bigint "rdv_id", null: false
    t.bigint "rdv_context_id", null: false
    t.index ["rdv_id", "rdv_context_id"], name: "index_rdv_contexts_rdvs_on_rdv_id_and_rdv_context_id", unique: true
  end

  create_table "rdvs", force: :cascade do |t|
    t.bigint "rdv_solidarites_rdv_id"
    t.datetime "starts_at", precision: nil
    t.integer "duration_in_min"
    t.datetime "cancelled_at", precision: nil
    t.bigint "rdv_solidarites_motif_id"
    t.bigint "rdv_solidarites_lieu_id"
    t.string "uuid"
    t.string "address"
    t.integer "created_by"
    t.integer "status"
    t.text "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organisation_id"
    t.datetime "last_webhook_update_received_at"
    t.index ["created_by"], name: "index_rdvs_on_created_by"
    t.index ["organisation_id"], name: "index_rdvs_on_organisation_id"
    t.index ["rdv_solidarites_rdv_id"], name: "index_rdvs_on_rdv_solidarites_rdv_id", unique: true
    t.index ["status"], name: "index_rdvs_on_status"
  end

  create_table "stats", force: :cascade do |t|
    t.integer "applicants_count"
    t.json "applicants_count_grouped_by_month"
    t.integer "rdvs_count"
    t.json "rdvs_count_grouped_by_month"
    t.integer "sent_invitations_count"
    t.json "sent_invitations_count_grouped_by_month"
    t.float "percentage_of_no_show"
    t.json "percentage_of_no_show_grouped_by_month"
    t.float "average_time_between_invitation_and_rdv_in_days"
    t.json "average_time_between_invitation_and_rdv_in_days_by_month"
    t.float "average_time_between_rdv_creation_and_start_in_days"
    t.json "average_time_between_rdv_creation_and_start_in_days_by_month"
    t.float "rate_of_applicants_with_rdv_seen_in_less_than_30_days"
    t.json "rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month"
    t.integer "agents_count"
    t.string "department_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "rate_of_applicants_autonomy"
    t.json "rate_of_applicants_autonomy_grouped_by_month"
    t.index ["department_number"], name: "index_stats_on_department_number", unique: true
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.string "url"
    t.string "secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "webhook_receipts", force: :cascade do |t|
    t.bigint "rdv_solidarites_rdv_id"
    t.datetime "rdvs_webhook_timestamp"
    t.datetime "sent_at"
    t.bigint "webhook_endpoint_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rdv_solidarites_rdv_id"], name: "index_webhook_receipts_on_rdv_solidarites_rdv_id", unique: true
    t.index ["webhook_endpoint_id"], name: "index_webhook_receipts_on_webhook_endpoint_id"
  end

  add_foreign_key "applicants", "departments"
  add_foreign_key "invitations", "applicants"
  add_foreign_key "invitations", "departments"
  add_foreign_key "invitations", "rdv_contexts"
  add_foreign_key "notifications", "applicants"
  add_foreign_key "organisations", "departments"
  add_foreign_key "organisations", "invitation_parameters", column: "invitation_parameters_id"
  add_foreign_key "rdv_contexts", "applicants"
  add_foreign_key "rdvs", "organisations"
  add_foreign_key "webhook_receipts", "webhook_endpoints"
end
