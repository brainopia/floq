class Floq::Schedulers::Test < Floq::Schedulers::Base
  attr_reader :pushed

  def initialize(*)
    super
    @pushed = []
  end

  def add(queues)
    super
    scheduler = self
    queues.each do |queue|
      queue.define_singleton_method :push do |data|
        super data
        scheduler.pushed << self
      end
    end
  end

  def drop
    pushed.uniq.each(&:drop)
    pushed.clear
  end

  def run
    check_handlers queues
    while queue = pushed.shift
      queue.pull_and_handle
    end
  end
end
