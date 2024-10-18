json.extract! paypal_account, :id, :email, :user_id, :default, :created_at, :updated_at
json.url paypal_account_url(paypal_account, format: :json)
