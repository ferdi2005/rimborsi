json.extract! expense, :id, :reimboursment_id, :purpose, :date, :amount, :car, :calculation_date, :departure, :arrival, :distance, :return_trip, :veichle_category_id, :brand, :model, :fuel_id, :quota_capitale, :carburante, :pneumatici, :manutenzione, :project_id, :created_at, :updated_at
json.url expense_url(expense, format: :json)
