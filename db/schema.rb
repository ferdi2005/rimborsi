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

ActiveRecord::Schema[7.2].define(version: 2026_09_24_134724) do
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
    t.decimal "quota_capitale", precision: 10, scale: 4
    t.decimal "carburante", precision: 10, scale: 4
    t.decimal "pneumatici", precision: 10, scale: 4
    t.decimal "manutenzione", precision: 10, scale: 4
    t.bigint "fund_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "vehicle_id"
    t.decimal "requested_amount", precision: 8, scale: 2
    t.string "project"
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

  create_table "rails_pulse_deployments", force: :cascade do |t|
    t.string "revision", null: false, comment: "Git SHA, tag, or version string"
    t.datetime "started_at", null: false, comment: "When the deployment started"
    t.datetime "finished_at", comment: "When the deployment finished (nil if still in progress or unknown)"
    t.text "metadata", comment: "JSON object of arbitrary deployment metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["revision"], name: "index_rails_pulse_deployments_on_revision"
    t.index ["started_at"], name: "index_rails_pulse_deployments_on_started_at"
  end

  create_table "rails_pulse_exception_groups", force: :cascade do |t|
    t.string "fingerprint", null: false, comment: "SHA256 of exception_class + relative first app-code location"
    t.string "exception_class", null: false, comment: "e.g. ActiveRecord::RecordNotFound"
    t.string "location", comment: "Relative first app-code frame, e.g. app/models/user.rb#save"
    t.text "message", comment: "Message from the most recent occurrence"
    t.datetime "first_seen_at", null: false
    t.datetime "last_seen_at", null: false
    t.integer "occurrence_count", default: 0, null: false
    t.string "status", default: "open", null: false, comment: "open, resolved, ignored"
    t.datetime "resolved_at", comment: "When the group was last resolved"
    t.boolean "preserve", default: false, null: false, comment: "Exempt from all automatic cleanup including occurrence rows"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exception_class"], name: "index_rp_exception_groups_on_class"
    t.index ["fingerprint"], name: "index_rp_exception_groups_on_fingerprint", unique: true
    t.index ["last_seen_at"], name: "index_rp_exception_groups_on_last_seen_at"
    t.index ["status"], name: "index_rp_exception_groups_on_status"
  end

  create_table "rails_pulse_exception_occurrences", force: :cascade do |t|
    t.bigint "exception_group_id", null: false, comment: "FK to the group this occurrence belongs to"
    t.string "exception_class", null: false
    t.text "message"
    t.text "backtrace", comment: "JSON array of {file, line, method} frames (first 50)"
    t.string "request_url", comment: "Nullable — web requests only"
    t.string "request_method", comment: "GET, POST, etc."
    t.string "environment", comment: "production, staging, etc."
    t.string "deploy_sha", comment: "Captured now even though Pro uses it — cannot backfill later"
    t.text "request_params", comment: "JSON hash of filtered request params — web requests only"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exception_group_id"], name: "index_rp_exception_occurrences_on_group_id"
    t.index ["occurred_at"], name: "index_rp_exception_occurrences_on_occurred_at"
  end

  create_table "rails_pulse_job_runs", force: :cascade do |t|
    t.bigint "job_id", null: false, comment: "Link to job definition"
    t.string "run_id", null: false, comment: "Adapter specific run id"
    t.decimal "duration", precision: 15, scale: 6, comment: "Execution duration in milliseconds"
    t.string "status", null: false, comment: "Execution status"
    t.string "error_class", comment: "Error class name"
    t.text "error_message", comment: "Error message"
    t.integer "attempts", default: 0, null: false, comment: "Retry attempts"
    t.datetime "occurred_at", precision: nil, null: false, comment: "When the job started"
    t.datetime "enqueued_at", precision: nil, comment: "When the job was enqueued"
    t.text "arguments", comment: "Serialized arguments"
    t.string "adapter", comment: "Queue adapter"
    t.text "tags", comment: "Execution tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "occurred_at"], name: "index_rails_pulse_job_runs_on_job_and_occurred"
    t.index ["job_id", "status"], name: "index_rails_pulse_job_runs_on_job_and_status"
    t.index ["job_id"], name: "index_rails_pulse_job_runs_on_job_id"
    t.index ["occurred_at"], name: "index_rails_pulse_job_runs_on_occurred_at"
    t.index ["run_id"], name: "index_rails_pulse_job_runs_on_run_id", unique: true
    t.index ["status"], name: "index_rails_pulse_job_runs_on_status"
  end

  create_table "rails_pulse_jobs", force: :cascade do |t|
    t.string "name", null: false, comment: "Job class name"
    t.string "queue_name", comment: "Default queue"
    t.text "description", comment: "Optional description"
    t.integer "runs_count", default: 0, null: false, comment: "Cache of total runs"
    t.integer "failures_count", default: 0, null: false, comment: "Cache of failed runs"
    t.integer "retries_count", default: 0, null: false, comment: "Cache of retried runs"
    t.decimal "avg_duration", precision: 15, scale: 6, comment: "Average duration in milliseconds"
    t.decimal "p95_duration", precision: 15, scale: 6, comment: "95th percentile duration in milliseconds"
    t.decimal "p99_duration", precision: 15, scale: 6, comment: "99th percentile duration in milliseconds"
    t.text "tags", comment: "JSON array of tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rails_pulse_jobs_on_name", unique: true
    t.index ["queue_name"], name: "index_rails_pulse_jobs_on_queue"
    t.index ["runs_count"], name: "index_rails_pulse_jobs_on_runs_count"
  end

  create_table "rails_pulse_operations", force: :cascade do |t|
    t.bigint "request_id", comment: "Link to the request"
    t.bigint "job_run_id", comment: "Link to a background job execution"
    t.bigint "query_id", comment: "Link to the normalized SQL query"
    t.string "operation_type", null: false, comment: "Type of operation (e.g., database, view, gem_call)"
    t.string "label", null: false, comment: "Display label: normalized SQL (≤255) for sql ops, controller#action / render path / cache key etc. for others"
    t.decimal "duration", precision: 15, scale: 6, null: false, comment: "Operation duration in milliseconds"
    t.string "codebase_location", comment: "File and line number (e.g., app/models/user.rb:25)"
    t.float "start_time", default: 0.0, null: false, comment: "Operation start time in milliseconds"
    t.datetime "occurred_at", precision: nil, null: false, comment: "When the request started"
    t.integer "row_count", comment: "Number of rows returned (SQL operations, Rails 7.1+)"
    t.boolean "cache_hit", comment: "Whether a cache_read operation hit the cache"
    t.text "actual_sql", comment: "Actual SQL that ran for sql operations — comment-stripped, unparameterized, unbounded"
    t.text "repeated_query_group", comment: "Normalized SQL key identifying an N+1 group"
    t.integer "repetition_count", comment: "Number of times this query pattern repeated in the request"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "query_id"], name: "idx_operations_for_aggregation"
    t.index ["job_run_id"], name: "index_rails_pulse_operations_on_job_run_id"
    t.index ["occurred_at", "duration", "operation_type"], name: "index_rails_pulse_operations_on_time_duration_type"
    t.index ["operation_type"], name: "index_rails_pulse_operations_on_operation_type"
    t.index ["query_id", "duration", "occurred_at"], name: "index_rails_pulse_operations_query_performance"
    t.index ["query_id", "occurred_at"], name: "index_rails_pulse_operations_on_query_and_time"
    t.index ["request_id"], name: "index_rails_pulse_operations_on_request_id"
    t.check_constraint "request_id IS NOT NULL OR job_run_id IS NOT NULL", name: "rails_pulse_operations_request_or_job_run"
  end

  create_table "rails_pulse_queries", force: :cascade do |t|
    t.string "hashed_sql", limit: 32, null: false, comment: "MD5 hash of normalized SQL for fast lookups and uniqueness"
    t.text "normalized_sql", null: false, comment: "Full normalized SQL query string (e.g., SELECT * FROM users WHERE id = ?)"
    t.datetime "analyzed_at", comment: "When query analysis was last performed"
    t.text "explain_plan", comment: "EXPLAIN output from actual SQL execution"
    t.text "issues", comment: "JSON array of detected performance issues"
    t.text "metadata", comment: "JSON object containing query complexity metrics"
    t.text "query_stats", comment: "JSON object with query characteristics analysis"
    t.text "backtrace_analysis", comment: "JSON object with call chain and N+1 detection"
    t.text "index_recommendations", comment: "JSON array of database index recommendations"
    t.text "n_plus_one_analysis", comment: "JSON object with enhanced N+1 query detection results"
    t.text "suggestions", comment: "JSON array of optimization recommendations"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hashed_sql"], name: "index_rails_pulse_queries_on_hashed_sql", unique: true
  end

  create_table "rails_pulse_requests", force: :cascade do |t|
    t.bigint "route_id", null: false, comment: "Link to the route"
    t.string "method", comment: "HTTP method used for this request (e.g., GET, POST)"
    t.decimal "duration", precision: 15, scale: 6, null: false, comment: "Total request duration in milliseconds"
    t.integer "status", null: false, comment: "HTTP status code (e.g., 200, 500)"
    t.boolean "is_error", default: false, null: false, comment: "True if status >= 500"
    t.string "request_uuid", null: false, comment: "Unique identifier for the request (e.g., UUID)"
    t.string "controller_action", comment: "Controller and action handling the request (e.g., PostsController#show)"
    t.datetime "occurred_at", precision: nil, null: false, comment: "When the request started"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
    t.integer "response_size_bytes", comment: "HTTP response body size in bytes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "route_id"], name: "idx_requests_for_aggregation"
    t.index ["occurred_at"], name: "index_rails_pulse_requests_on_occurred_at"
    t.index ["request_uuid"], name: "index_rails_pulse_requests_on_request_uuid", unique: true
    t.index ["route_id", "occurred_at"], name: "index_rails_pulse_requests_on_route_id_and_occurred_at"
    t.index ["route_id"], name: "index_rails_pulse_requests_on_route_id"
  end

  create_table "rails_pulse_routes", force: :cascade do |t|
    t.text "http_methods", null: false, comment: "JSON array of HTTP methods accepted by this route (e.g., [\"GET\",\"POST\"])"
    t.string "path", null: false, comment: "Normalized request path (e.g., /posts/:id)"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
    t.string "controller_action", comment: "Rails controller and action handling this route (e.g., articles#show)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller_action", "path"], name: "index_rails_pulse_routes_on_controller_action_and_path", unique: true
    t.index ["path"], name: "index_rails_pulse_routes_on_path"
    t.index ["path"], name: "index_rails_pulse_routes_on_path_without_action", unique: true, where: "(controller_action IS NULL)"
  end

  create_table "rails_pulse_summaries", force: :cascade do |t|
    t.datetime "period_start", null: false, comment: "Start of the aggregation period"
    t.datetime "period_end", null: false, comment: "End of the aggregation period"
    t.string "period_type", null: false, comment: "Aggregation period type: hour, day, week, month"
    t.string "summarizable_type", null: false
    t.bigint "summarizable_id", null: false, comment: "Link to Route or Query"
    t.integer "count", default: 0, null: false, comment: "Total number of requests/operations"
    t.float "avg_duration", comment: "Average duration in milliseconds"
    t.float "min_duration", comment: "Minimum duration in milliseconds"
    t.float "max_duration", comment: "Maximum duration in milliseconds"
    t.float "p50_duration", comment: "50th percentile duration"
    t.float "p95_duration", comment: "95th percentile duration"
    t.float "p99_duration", comment: "99th percentile duration"
    t.float "total_duration", comment: "Total duration in milliseconds"
    t.float "stddev_duration", comment: "Standard deviation of duration"
    t.integer "error_count", default: 0, comment: "Number of error responses (5xx)"
    t.integer "success_count", default: 0, comment: "Number of successful responses"
    t.integer "status_2xx", default: 0, comment: "Number of 2xx responses"
    t.integer "status_3xx", default: 0, comment: "Number of 3xx responses"
    t.integer "status_4xx", default: 0, comment: "Number of 4xx responses"
    t.integer "status_5xx", default: 0, comment: "Number of 5xx responses"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_rails_pulse_summaries_on_created_at"
    t.index ["period_start"], name: "index_rails_pulse_summaries_on_period_start"
    t.index ["period_type", "period_start"], name: "index_rails_pulse_summaries_on_period"
    t.index ["summarizable_id"], name: "index_rails_pulse_summaries_on_summarizable_id"
    t.index ["summarizable_type", "summarizable_id", "period_type", "period_start"], name: "idx_pulse_summaries_unique", unique: true
    t.index ["summarizable_type", "summarizable_id"], name: "index_rails_pulse_summaries_on_summarizable"
  end

  create_table "reimboursements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "bank_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.bigint "payment_id"
    t.string "role"
    t.string "role_other"
    t.text "project"
    t.bigint "fund_id"
    t.index ["bank_account_id"], name: "index_reimboursements_on_bank_account_id"
    t.index ["fund_id"], name: "index_reimboursements_on_fund_id"
    t.index ["payment_id"], name: "index_reimboursements_on_payment_id"
    t.index ["user_id"], name: "index_reimboursements_on_user_id"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.boolean "active", default: true, null: false
    t.string "fiscal_code"
    t.string "locale", default: "it"
    t.boolean "seen_whats_new", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
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
  add_foreign_key "rails_pulse_exception_occurrences", "rails_pulse_exception_groups", column: "exception_group_id"
  add_foreign_key "rails_pulse_job_runs", "rails_pulse_jobs", column: "job_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_job_runs", column: "job_run_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_queries", column: "query_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_requests", column: "request_id"
  add_foreign_key "rails_pulse_requests", "rails_pulse_routes", column: "route_id"
  add_foreign_key "reimboursements", "bank_accounts"
  add_foreign_key "reimboursements", "funds"
  add_foreign_key "reimboursements", "payments"
  add_foreign_key "reimboursements", "users"
  add_foreign_key "vehicles", "users"
end
