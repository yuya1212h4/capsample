app_path = "/var/www/capsample/current"

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = File.expand_path('Gemfile', "/var/www/capsample/current")
end
worker_processes 1
# worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)

working_directory "#{app_path}/current"
listen "#{app_path}/shared/tmp/sockets/unicorn.sock"
# pid "#{app_path}/shared/tmp/pids/unicorn.pid"
pid "#{app_path}/shared/var/run/unicorn.pid"
stderr_path "#{app_path}/shared/log/unicorn.stderr.log"
stdout_path "#{app_path}/shared/log/unicorn.stdout.log"

# listen 3000
listen File.expand_path('/var/www/capsample/shared/var/run/unicorn.sock', __FILE__)
timeout 180

preload_app true
GC.respond_to?(:copy_on_write_friendly=) && GC.copy_on_write_friendly = true

check_client_connection false

run_once = true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!

  if run_once
    run_once = false # prevent from firing again
  end

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH => e
      logger.error e
    end
  end
end

after_fork do |_server, _worker|
  defined?(ActiveRecord::Base) && ActiveRecord::Base.establish_connection
end
