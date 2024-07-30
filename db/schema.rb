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

ActiveRecord::Schema[7.1].define(version: 2024_07_23_232305) do
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

  create_table "address_geocodings", force: :cascade do |t|
    t.string "post_code"
    t.string "city_code"
    t.float "latitude"
    t.float "longitude"
    t.string "city"
    t.string "department_number"
    t.bigint "user_id", null: false
    t.string "street"
    t.string "house_number"
    t.string "street_ban_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_address_geocodings_on_user_id"
  end

  create_table "agent_roles", force: :cascade do |t|
    t.string "access_level", default: "basic", null: false
    t.bigint "agent_id", null: false
    t.bigint "organisation_id", null: false
    t.bigint "rdv_solidarites_agent_role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_webhook_update_received_at"
    t.boolean "authorized_to_export_csv", default: false
    t.index ["access_level"], name: "index_agent_roles_on_access_level"
    t.index ["agent_id", "organisation_id"], name: "index_agent_roles_on_agent_id_and_organisation_id", unique: true
    t.index ["agent_id"], name: "index_agent_roles_on_agent_id"
    t.index ["organisation_id"], name: "index_agent_roles_on_organisation_id"
    t.index ["rdv_solidarites_agent_role_id"], name: "index_agent_roles_on_rdv_solidarites_agent_role_id", unique: true
  end

  create_table "agents", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "rdv_solidarites_agent_id"
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_webhook_update_received_at"
    t.boolean "super_admin", default: false
    t.datetime "last_sign_in_at"
    t.string "inclusion_connect_open_id_sub"
    t.index ["email"], name: "index_agents_on_email", unique: true
    t.index ["inclusion_connect_open_id_sub"], name: "index_agents_on_inclusion_connect_open_id_sub", unique: true, where: "(inclusion_connect_open_id_sub IS NOT NULL)"
    t.index ["rdv_solidarites_agent_id"], name: "index_agents_on_rdv_solidarites_agent_id", unique: true
  end

  create_table "agents_rdvs", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "rdv_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "rdv_id"], name: "index_agents_rdvs_on_agent_id_and_rdv_id", unique: true
  end

  create_table "archives", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "archiving_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organisation_id", null: false
    t.index ["organisation_id"], name: "index_archives_on_organisation_id"
    t.index ["user_id"], name: "index_archives_on_user_id"
  end

  create_table "category_configurations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invitation_formats", default: ["sms", "email", "postal"], null: false, array: true
    t.boolean "convene_user", default: true
    t.integer "number_of_days_before_action_required", default: 10
    t.boolean "invite_to_user_organisations_only", default: true
    t.boolean "rdv_with_referents", default: false
    t.bigint "motif_category_id"
    t.bigint "file_configuration_id"
    t.bigint "organisation_id"
    t.string "template_rdv_title_override"
    t.string "template_rdv_title_by_phone_override"
    t.string "template_user_designation_override"
    t.string "template_rdv_purpose_override"
    t.integer "number_of_days_between_periodic_invites"
    t.integer "day_of_the_month_periodic_invites"
    t.integer "position", default: 0
    t.integer "department_position", default: 0
    t.string "phone_number"
    t.string "email_to_notify_no_available_slots"
    t.string "email_to_notify_rdv_changes"
    t.index ["file_configuration_id"], name: "index_category_configurations_on_file_configuration_id"
    t.index ["motif_category_id"], name: "index_category_configurations_on_motif_category_id"
    t.index ["organisation_id"], name: "index_category_configurations_on_organisation_id"
  end

  create_table "csv_exports", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.string "structure_type", null: false
    t.bigint "structure_id", null: false
    t.datetime "purged_at"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "request_params"
    t.index ["agent_id"], name: "index_csv_exports_on_agent_id"
    t.index ["structure_type", "structure_id"], name: "index_csv_exports_on_structure"
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
    t.boolean "display_in_stats", default: true
    t.string "carnet_de_bord_deploiement_id"
  end

  create_table "file_configurations", force: :cascade do |t|
    t.string "sheet_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title_column"
    t.string "first_name_column"
    t.string "last_name_column"
    t.string "role_column"
    t.string "email_column"
    t.string "phone_number_column"
    t.string "birth_date_column"
    t.string "birth_name_column"
    t.string "address_first_field_column"
    t.string "address_second_field_column"
    t.string "address_third_field_column"
    t.string "address_fourth_field_column"
    t.string "address_fifth_field_column"
    t.string "affiliation_number_column"
    t.string "france_travail_id_column"
    t.string "nir_column"
    t.string "department_internal_id_column"
    t.string "rights_opening_date_column"
    t.string "organisation_search_terms_column"
    t.string "referent_email_column"
    t.string "tags_column"
  end

  create_table "follow_ups", force: :cascade do |t|
    t.string "status"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "motif_category_id"
    t.datetime "closed_at"
    t.index ["motif_category_id"], name: "index_follow_ups_on_motif_category_id"
    t.index ["status"], name: "index_follow_ups_on_status"
    t.index ["user_id"], name: "index_follow_ups_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "format"
    t.string "link"
    t.string "rdv_solidarites_token"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "clicked", default: false
    t.string "help_phone_number"
    t.bigint "department_id"
    t.bigint "rdv_solidarites_lieu_id"
    t.bigint "follow_up_id"
    t.datetime "valid_until"
    t.string "uuid"
    t.boolean "rdv_with_referents", default: false
    t.string "trigger", default: "manual", null: false
    t.string "delivery_status"
    t.datetime "last_brevo_webhook_received_at"
    t.index ["department_id"], name: "index_invitations_on_department_id"
    t.index ["follow_up_id"], name: "index_invitations_on_follow_up_id"
    t.index ["trigger"], name: "index_invitations_on_trigger"
    t.index ["user_id"], name: "index_invitations_on_user_id"
    t.index ["uuid"], name: "index_invitations_on_uuid", unique: true
  end

  create_table "invitations_organisations", id: false, force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "invitation_id", null: false
    t.index ["organisation_id", "invitation_id"], name: "index_invitations_orgas_on_orga_id_and_invitation_id", unique: true
  end

  create_table "lieux", force: :cascade do |t|
    t.bigint "rdv_solidarites_lieu_id"
    t.string "name"
    t.string "address"
    t.string "phone_number"
    t.datetime "last_webhook_update_received_at"
    t.bigint "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_lieux_on_organisation_id"
  end

  create_table "messages_configurations", force: :cascade do |t|
    t.string "direction_names", array: true
    t.string "sender_city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "letter_sender_name"
    t.string "signature_lines", array: true
    t.string "help_address"
    t.boolean "display_europe_logos", default: false
    t.string "sms_sender_name"
    t.boolean "display_department_logo", default: true
    t.bigint "organisation_id"
    t.boolean "display_france_travail_logo", default: false
    t.index ["organisation_id"], name: "index_messages_configurations_on_organisation_id"
  end

  create_table "motif_categories", force: :cascade do |t|
    t.string "short_name"
    t.string "name"
    t.bigint "rdv_solidarites_motif_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "template_id"
    t.boolean "optional_rdv_subscription", default: false
    t.boolean "leads_to_orientation", default: false
    t.index ["rdv_solidarites_motif_category_id"], name: "index_motif_categories_on_rdv_solidarites_motif_category_id", unique: true
    t.index ["short_name"], name: "index_motif_categories_on_short_name", unique: true
    t.index ["template_id"], name: "index_motif_categories_on_template_id"
  end

  create_table "motifs", force: :cascade do |t|
    t.bigint "rdv_solidarites_motif_id"
    t.string "name"
    t.boolean "reservable_online"
    t.datetime "deleted_at"
    t.bigint "rdv_solidarites_service_id"
    t.boolean "collectif"
    t.string "location_type"
    t.datetime "last_webhook_update_received_at"
    t.bigint "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "follow_up", default: false
    t.bigint "motif_category_id"
    t.text "instruction_for_rdv", default: ""
    t.index ["motif_category_id"], name: "index_motifs_on_motif_category_id"
    t.index ["organisation_id"], name: "index_motifs_on_organisation_id"
    t.index ["rdv_solidarites_motif_id"], name: "index_motifs_on_rdv_solidarites_motif_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.string "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "rdv_solidarites_rdv_id"
    t.string "format"
    t.bigint "participation_id"
    t.string "delivery_status"
    t.datetime "last_brevo_webhook_received_at"
    t.index ["participation_id"], name: "index_notifications_on_participation_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name"
    t.string "phone_number"
    t.string "email"
    t.bigint "rdv_solidarites_organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "department_id"
    t.datetime "last_webhook_update_received_at"
    t.string "slug"
    t.string "logo_filename"
    t.string "safir_code"
    t.string "organisation_type"
    t.index ["department_id"], name: "index_organisations_on_department_id"
    t.index ["rdv_solidarites_organisation_id"], name: "index_organisations_on_rdv_solidarites_organisation_id", unique: true
  end

  create_table "orientation_types", force: :cascade do |t|
    t.string "casf_category"
    t.string "name"
    t.bigint "department_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_orientation_types_on_department_id"
  end

  create_table "orientations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organisation_id", null: false
    t.bigint "agent_id"
    t.date "starts_at"
    t.date "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "orientation_type_id"
    t.index ["agent_id"], name: "index_orientations_on_agent_id"
    t.index ["organisation_id"], name: "index_orientations_on_organisation_id"
    t.index ["orientation_type_id"], name: "index_orientations_on_orientation_type_id"
    t.index ["user_id"], name: "index_orientations_on_user_id"
  end

  create_table "parcours_documents", force: :cascade do |t|
    t.bigint "department_id", null: false
    t.bigint "user_id", null: false
    t.bigint "agent_id", null: false
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "document_date"
    t.index ["agent_id"], name: "index_parcours_documents_on_agent_id"
    t.index ["department_id"], name: "index_parcours_documents_on_department_id"
    t.index ["type"], name: "index_parcours_documents_on_type"
    t.index ["user_id"], name: "index_parcours_documents_on_user_id"
  end

  create_table "participations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "rdv_id", null: false
    t.string "status", default: "unknown"
    t.bigint "rdv_solidarites_participation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "follow_up_id"
    t.string "created_by", null: false
    t.boolean "convocable", default: false, null: false
    t.bigint "rdv_solidarites_agent_prescripteur_id"
    t.index ["follow_up_id"], name: "index_participations_on_follow_up_id"
    t.index ["status"], name: "index_participations_on_status"
    t.index ["user_id", "rdv_id"], name: "index_participations_on_user_id_and_rdv_id", unique: true
  end

  create_table "rdvs", force: :cascade do |t|
    t.bigint "rdv_solidarites_rdv_id"
    t.datetime "starts_at", precision: nil
    t.integer "duration_in_min"
    t.datetime "cancelled_at", precision: nil
    t.string "uuid"
    t.string "address"
    t.string "created_by"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organisation_id"
    t.text "context"
    t.datetime "last_webhook_update_received_at"
    t.bigint "motif_id"
    t.bigint "lieu_id"
    t.integer "users_count", default: 0
    t.integer "max_participants_count"
    t.index ["created_by"], name: "index_rdvs_on_created_by"
    t.index ["lieu_id"], name: "index_rdvs_on_lieu_id"
    t.index ["motif_id"], name: "index_rdvs_on_motif_id"
    t.index ["organisation_id"], name: "index_rdvs_on_organisation_id"
    t.index ["rdv_solidarites_rdv_id"], name: "index_rdvs_on_rdv_solidarites_rdv_id", unique: true
    t.index ["status"], name: "index_rdvs_on_status"
  end

  create_table "referent_assignations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "agent_id", null: false
    t.index ["user_id", "agent_id"], name: "index_referent_assignations_on_user_id_and_agent_id", unique: true
  end

  create_table "stats", force: :cascade do |t|
    t.integer "users_count"
    t.json "users_count_grouped_by_month"
    t.integer "rdvs_count"
    t.json "rdvs_count_grouped_by_month"
    t.integer "sent_invitations_count"
    t.json "sent_invitations_count_grouped_by_month"
    t.float "average_time_between_invitation_and_rdv_in_days"
    t.json "average_time_between_invitation_and_rdv_in_days_by_month"
    t.float "rate_of_users_oriented_in_less_than_30_days"
    t.json "rate_of_users_oriented_in_less_than_30_days_by_month"
    t.integer "agents_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "rate_of_autonomous_users"
    t.json "rate_of_autonomous_users_grouped_by_month"
    t.string "statable_type"
    t.bigint "statable_id"
    t.float "rate_of_no_show_for_convocations"
    t.json "rate_of_no_show_for_convocations_grouped_by_month"
    t.float "rate_of_no_show_for_invitations"
    t.json "rate_of_no_show_for_invitations_grouped_by_month"
    t.float "rate_of_users_oriented"
    t.json "rate_of_users_oriented_grouped_by_month"
    t.integer "users_with_rdv_count"
    t.json "users_with_rdv_count_grouped_by_month"
    t.float "rate_of_users_oriented_in_less_than_15_days"
    t.json "rate_of_users_oriented_in_less_than_15_days_by_month"
    t.index ["statable_type", "statable_id"], name: "index_stats_on_statable"
  end

  create_table "tag_organisations", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_tag_organisations_on_organisation_id"
    t.index ["tag_id"], name: "index_tag_organisations_on_tag_id"
  end

  create_table "tag_users", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_tag_users_on_tag_id"
    t.index ["user_id"], name: "index_tag_users_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "templates", force: :cascade do |t|
    t.string "model"
    t.string "rdv_title"
    t.string "rdv_title_by_phone"
    t.string "rdv_purpose"
    t.string "user_designation"
    t.string "rdv_subject"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "custom_sentence"
    t.boolean "display_mandatory_warning", default: false
    t.text "punishable_warning", default: "", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "uid"
    t.bigint "rdv_solidarites_user_id"
    t.string "affiliation_number"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "department_internal_id"
    t.string "first_name"
    t.string "last_name"
    t.string "address"
    t.string "phone_number"
    t.string "email"
    t.string "title"
    t.date "birth_date"
    t.date "rights_opening_date"
    t.string "birth_name"
    t.datetime "deleted_at"
    t.datetime "last_webhook_update_received_at"
    t.string "nir"
    t.string "france_travail_id"
    t.string "carnet_de_bord_carnet_id"
    t.string "created_through"
    t.bigint "old_rdv_solidarites_user_id"
    t.string "created_from_structure_type"
    t.bigint "created_from_structure_id"
    t.index ["created_from_structure_type", "created_from_structure_id"], name: "index_users_on_created_from_structure"
    t.index ["department_internal_id"], name: "index_users_on_department_internal_id"
    t.index ["email"], name: "index_users_on_email"
    t.index ["nir"], name: "index_users_on_nir"
    t.index ["phone_number"], name: "index_users_on_phone_number"
    t.index ["rdv_solidarites_user_id"], name: "index_users_on_rdv_solidarites_user_id", unique: true
    t.index ["uid"], name: "index_users_on_uid"
  end

  create_table "users_organisations", force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["organisation_id", "user_id"], name: "index_applicants_orgas_on_orga_id_and_applicant_id", unique: true
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.string "url"
    t.string "secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subscriptions", array: true
    t.string "signature_type", default: "hmac"
    t.bigint "organisation_id"
    t.index ["organisation_id"], name: "index_webhook_endpoints_on_organisation_id"
  end

  create_table "webhook_receipts", force: :cascade do |t|
    t.bigint "resource_id"
    t.datetime "timestamp"
    t.bigint "webhook_endpoint_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resource_model"
    t.index ["resource_model", "resource_id", "webhook_endpoint_id"], name: "index_on_webhook_endpoint_and_resource_model_and_id"
    t.index ["webhook_endpoint_id"], name: "index_webhook_receipts_on_webhook_endpoint_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "address_geocodings", "users"
  add_foreign_key "agent_roles", "agents"
  add_foreign_key "agent_roles", "organisations"
  add_foreign_key "archives", "organisations"
  add_foreign_key "archives", "users"
  add_foreign_key "category_configurations", "file_configurations"
  add_foreign_key "category_configurations", "motif_categories"
  add_foreign_key "category_configurations", "organisations"
  add_foreign_key "csv_exports", "agents"
  add_foreign_key "follow_ups", "motif_categories"
  add_foreign_key "follow_ups", "users"
  add_foreign_key "invitations", "departments"
  add_foreign_key "invitations", "follow_ups"
  add_foreign_key "invitations", "users"
  add_foreign_key "lieux", "organisations"
  add_foreign_key "messages_configurations", "organisations"
  add_foreign_key "motif_categories", "templates"
  add_foreign_key "motifs", "motif_categories"
  add_foreign_key "motifs", "organisations"
  add_foreign_key "notifications", "participations"
  add_foreign_key "organisations", "departments"
  add_foreign_key "orientation_types", "departments"
  add_foreign_key "orientations", "agents"
  add_foreign_key "orientations", "organisations"
  add_foreign_key "orientations", "orientation_types"
  add_foreign_key "orientations", "users"
  add_foreign_key "parcours_documents", "agents"
  add_foreign_key "parcours_documents", "departments"
  add_foreign_key "parcours_documents", "users"
  add_foreign_key "participations", "follow_ups"
  add_foreign_key "rdvs", "lieux"
  add_foreign_key "rdvs", "motifs"
  add_foreign_key "rdvs", "organisations"
  add_foreign_key "tag_organisations", "organisations"
  add_foreign_key "tag_organisations", "tags"
  add_foreign_key "tag_users", "tags"
  add_foreign_key "tag_users", "users"
  add_foreign_key "webhook_receipts", "webhook_endpoints"
end
