class Turbo::Debouncer
  attr_reader :delay, :max_delay, :delaying_since, :scheduled_task

  DEFAULT_DELAY = 0.5
  DEFAULT_MAX_DELAY = 5

  def initialize(delay: DEFAULT_DELAY, max_delay: DEFAULT_MAX_DELAY)
    @delay = delay
    @max_delay = max_delay
    @delaying_since = nil
    @scheduled_task = nil
  end

  def debounce(&block)
    wait if delayed_long_enough?
    scheduled_task&.cancel unless scheduled_task&.complete?
    @scheduled_task = Concurrent::ScheduledTask.execute(delay, &block)
    @delaying_since ||= now if max_delay
  end

  def wait
    scheduled_task&.wait(wait_timeout).tap do
      @delaying_since = nil
    end
  end

  private
    def wait_timeout
      delay + 1
    end

    def delayed_long_enough?
      delaying_since && now - delaying_since >= max_delay
    end

    def now
      Concurrent.monotonic_time :second
    end
end
