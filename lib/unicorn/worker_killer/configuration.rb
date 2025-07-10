module Unicorn::WorkerKiller
  class Configuration
    attr_accessor :max_quit, :max_term, :sleep_interval, :before_kill, :after_kill

    def initialize
      self.max_quit = 10
      self.max_term = 15
      self.sleep_interval = 1
      self.before_kill = []
      self.after_kill = []
    end

    # Add a callback to be executed before kill_self
    def before_kill_hook(&block)
      self.before_kill << block if block_given?
    end

    # Add a callback to be executed after kill_self
    def after_kill_hook(&block)
      self.after_kill << block if block_given?
    end
  end
end
