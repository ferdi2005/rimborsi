json.extract! bank_account, :id, :user_id, :iban, :owner, :address, :cap, :town, :fiscal_code, :default, :created_at, :updated_at
json.url bank_account_url(bank_account, format: :json)
