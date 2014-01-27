class Floq::Schedulers::Greedy < Floq::Schedulers::Base
  MAX_DELAY = 5
  HISTORY_SIZE = 3

  class Wrapper < SimpleDelegator
    def pull_and_handle
      @status ||= Array.new(HISTORY_SIZE, true)
      @status.shift
      pulled_status = super
      @status.push pulled_status
      missed_times = @status.count(false)
      sleep MAX_DELAY * missed_times.to_f / HISTORY_SIZE
      pulled_status
    end
  end

  def run
    check_handler
    queues.each do |queue|
      Thread.new do
        loop { Wrapper.new(queue).pull_and_handle }
      end
    end
    sleep
  end
end
