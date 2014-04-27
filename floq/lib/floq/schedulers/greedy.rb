class Floq::Schedulers::Greedy < Floq::Schedulers::Base
  require_relative 'greedy/pool'

  MAX_DELAY = 5
  HISTORY_SIZE = 3

  class Wrapper
    def initialize(queue)
      @queue  = queue
      @status = Array.new(HISTORY_SIZE, true)
    end

    def pull_and_handle
      @status.shift
      pulled_status = @queue.pull_and_handle
      @status.push pulled_status
      missed_times = @status.count(false)
      if missed_times > 0
        sleep MAX_DELAY * missed_times.to_f / HISTORY_SIZE
      end
      pulled_status
    end
  end

  def run
    check_handler
    start_cleanup_thread

    pool = Pool.new options.fetch(:pool, 20)
    queues.each do |queue|
      wrapper = Wrapper.new queue
      processor = -> do
        pool.process do
          wrapper.pull_and_handle
          processor.call
        end
      end
      processor.call
    end
    sleep
  end
end
