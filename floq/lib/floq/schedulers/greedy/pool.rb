class Floq::Schedulers::Greedy::Pool
  def initialize(number)
    @queue = Queue.new

    number.times do
      Thread.new do
        loop do
          job = @queue.pop
          job.call rescue nil
        end
      end
    end
  end

  def process(&block)
    @queue << block
  end
end
