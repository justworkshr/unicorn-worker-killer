# Example configuration showing how to use the callback hooks

require 'unicorn/worker_killer'

# Configure unicorn-worker-killer with custom callbacks
Unicorn::WorkerKiller.configure do |config|
  # Standard configuration
  config.max_quit = 10
  config.max_term = 15
  config.sleep_interval = 1
  
  # Before kill callback - executed before sending the kill signal
  config.before_kill_hook do |logger, start_time, worker_pid, kill_attempts|
    alive_time = Time.now - start_time
    logger.info "[BEFORE KILL] Worker #{worker_pid} has been alive for #{alive_time.round(2)}s, attempt #{kill_attempts}"
    
    # Example: Send metrics to monitoring system
    # StatsD.increment('unicorn.worker.kill.attempt')
    
    # Example: Log to external system
    # ExternalLogger.log("Worker #{worker_pid} about to be killed")
    
    # Example: Cleanup application-specific resources
    # ApplicationCache.clear_worker_cache(worker_pid)
  end
  
  # After kill callback - executed after sending the kill signal
  config.after_kill_hook do |logger, start_time, worker_pid, kill_attempts, signal|
    alive_time = Time.now - start_time
    logger.info "[AFTER KILL] Sent #{signal} signal to worker #{worker_pid} after #{alive_time.round(2)}s alive"
    
    # Example: Record final metrics
    # StatsD.timing('unicorn.worker.lifetime', alive_time)
    # StatsD.increment("unicorn.worker.kill.signal.#{signal.downcase}")
    
    # Example: Notify external systems
    # SlackNotifier.notify("Worker #{worker_pid} killed with #{signal} signal")
    
    # Example: Update database or cache
    # WorkerStatsDB.record_kill(worker_pid, signal, alive_time, kill_attempts)
  end
end

# Example rack application setup
class ExampleApp
  def call(env)
    [200, {'Content-Type' => 'text/plain'}, ['Hello World']]
  end
end

# Use the worker killer modules
use Unicorn::WorkerKiller::MaxRequests, 100, 200, true
use Unicorn::WorkerKiller::Oom, (64 * 1024 * 1024), (128 * 1024 * 1024), 10, true

run ExampleApp.new
