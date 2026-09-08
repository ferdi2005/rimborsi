# Puma configuration file
# https://github.com/puma/puma/blob/master/examples/config.rb

threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

# Specifies the `environment` that Puma will run in
environment ENV.fetch("RAILS_ENV", "development")

# Specifies the `pidfile` that Puma will use
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Specifies the number of `workers` to boot in clustered mode
workers ENV.fetch("WEB_CONCURRENCY", 0)

preload_app!

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart

# Automatically accept systemd activated sockets without unlinking them
bind_to_activated_sockets

if ENV.fetch("RAILS_ENV", "development") == "development"
  port ENV.fetch("PORT", 3000)
elsif ENV["PUMA_SOCKET"]
  bind ENV["PUMA_SOCKET"]
end
