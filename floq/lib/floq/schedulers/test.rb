class Floq::Schedulers::Test < Floq::Schedulers::Base
  attr_reader :pushed_queues

  def initialize(*)
    super
    make_queues_testable
    @pushed_queues = []
  end

  def drop
    pushed_queues.uniq.each(&:drop)
    pushed_queues.clear
  end

  def drop_all
    queues.each(&:drop)
    pushed_queues.clear
  end

  def run
    check_handler

    while queue = next_queue!
      queue.pull_and_handle
    end
  end

  private

  def next_queue!
    pushed_queues.shuffle! if options[:random]
    pushed_queues.shift
  end

  def make_queues_testable
    scheduler = self
    queues.each do |queue|
      queue.define_singleton_method :push do |data|
        super data
        scheduler.pushed_queues << self
      end
    end
  end
end
