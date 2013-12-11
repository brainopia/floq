class Floq::Schedulers::Test < Floq::Schedulers::Base
  attr_reader :pushed

  def initialize(*)
    super
    @pushed = []
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
    while queue = pushed.shift
      queue.pull_and_handle
    end
  end
end
