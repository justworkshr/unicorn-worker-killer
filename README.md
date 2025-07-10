# unicorn-worker-killer

[Unicorn](http://unicorn.bogomips.org/) is widely used HTTP-server for Rack applications. One thing we thought Unicorn missed, is killing the Unicorn workers based on the number of requests and consumed memories.

`unicorn-worker-killer` gem provides automatic restart of Unicorn workers based on 1) max number of requests, and 2) process memory size (RSS), without affecting any requests. This will greatly improves site's stability by avoiding unexpected memory exhaustion at the application nodes.

# Install

No external process like `god` is required. Just install one gem: `unicorn-worker-killer`.

    gem 'unicorn-worker-killer'

# Usage

Add these lines to your `config.ru`. (These lines should be added above the `require ::File.expand_path('../config/environment',  __FILE__)` line.

    # Unicorn self-process killer
    require 'unicorn/worker_killer'
    
    # Max requests per worker
    use Unicorn::WorkerKiller::MaxRequests, 3072, 4096
    
    # Max memory size (RSS) per worker
    use Unicorn::WorkerKiller::Oom, (192*(1024**2)), (256*(1024**2))

This gem provides two modules.

### `Unicorn::WorkerKiller::MaxRequests(max_requests_min=3072, max_requests_max=4096, verbose=false)`

This module automatically restarts the Unicorn workers, based on the number of requests which worker processed.

`max_requests_min` and `max_requests_max` specify the min and max of maximum requests per worker. The actual limit is decided by rand() between `max_requests_min` and `max_requests_max` per worker, to prevent all workers to be dead at the same time. Once the number exceeds the limit, that worker is automatically restarted.

If `verbose` is set to true, then after every request, your log will show the requests left before restart.  This logging is done at the `info` level.

### `Unicorn::WorkerKiller::Oom(memory_limit_min=(1024\*\*3), memory_limit_max=(2\*(1024\*\*3)), check_cycle = 16, verbose = false)`

This module automatically restarts the Unicorn workers, based on its memory size.

`memory_limit_min` and `memory_limit_max` specify the min and max of maximum memory in bytes per worker. The actual limit is decided by rand() between `memory_limit_min` and `memory_limit_max` per worker, to prevent all workers to be dead at the same time.  Once the memory size exceeds `memory_size`, that worker is automatically restarted.

The memory size check is done in every `check_cycle` requests.

If `verbose` is set to true, then every memory size check will be shown in your logs.   This logging is done at the `info` level.

## Configuration and Callbacks

You can configure `unicorn-worker-killer` and add custom callbacks that execute before or after a worker is killed:

```ruby
# Configure unicorn-worker-killer with callbacks
Unicorn::WorkerKiller.configure do |config|
  config.max_quit = 10
  config.max_term = 15
  config.sleep_interval = 1
  
  # Add a callback to execute before killing a worker
  config.before_kill_hook do |logger, start_time, worker_pid, kill_attempts|
    logger.info "About to kill worker #{worker_pid} (attempt #{kill_attempts})"
    # Add custom logic here, such as:
    # - Logging to external monitoring system
    # - Sending notifications
    # - Cleaning up resources
  end
  
  # Add a callback to execute after killing a worker
  config.after_kill_hook do |logger, start_time, worker_pid, kill_attempts, signal|
    logger.info "Sent #{signal} signal to worker #{worker_pid}"
    # Add custom logic here, such as:
    # - Recording metrics
    # - Updating external systems
    # - Additional cleanup
  end
end
```

### Callback Parameters

**Before kill callbacks** receive:
- `logger`: The logger instance
- `start_time`: When the worker process started
- `worker_pid`: The process ID of the worker being killed
- `kill_attempts`: Number of kill attempts made so far

**After kill callbacks** receive:
- `logger`: The logger instance
- `start_time`: When the worker process started
- `worker_pid`: The process ID of the worker being killed
- `kill_attempts`: Number of kill attempts made so far
- `signal`: The signal that was sent (:QUIT, :TERM, or :KILL)

Callbacks are executed in a safe manner - if a callback raises an exception, it will be logged as an error but won't prevent the worker from being killed.

# Special Thanks

- [@hotchpotch](http://github.com/hotchpotch/) for the [original idea](https://gist.github.com/hotchpotch/1258681)

