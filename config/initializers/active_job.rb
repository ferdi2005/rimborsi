# Active Job configuration
Rails.application.configure do
  # Configure the job queue adapter
  # In development, you can use :inline for immediate execution
  # In production, consider using :sidekiq, :delayed_job, or :resque
  config.active_job.queue_adapter = Rails.env.production? ? :sidekiq : :async

  # Job queue name prefix (optional)
  # config.active_job.queue_name_prefix = "rimborsi_#{Rails.env}"
end
