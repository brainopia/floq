class Floq::Schedulers::Test < Floq::Schedulers::Base
  attr_reader :testable_queues, :pushed_queues

  def initialize(*)
    super
    @testable_queues = []
    @pushed_queues   = []
  end

  def drop
    pushed_queues.uniq.each(&:drop)
    pushed_queues.clear
  end

  def run
    check_handler
    make_queues_testable
    
    while queue = pushed_queues.shift
      queue.pull_and_handle
    end
  end

  private

  def make_queues_testable
    scheduler = self
    queues.each do |queue|
      queue.define_singleton_method :push do |data|
        super data
        scheduler.pushed_queues << self
      end
    end
    testable_queues.concat queues
    queues.clear
  end
end
