class Floq::Plugins::Batcher
  incldue Floq::Plugins::Base

  def initialize(base, size=200)
    super
    @size = size
    @cache = Hash.new {|h,k| h[k] = [] }
    @mutex = Hash.new do |h,k|
      Thread.exclusive do
        h[k] ||= Mutex.new
      end
    end
  end

  def peek(queue)
    message = @cache[queue].first
    return message if message

    @cache[queue] = @base.peek_batch queue, @size
    @cache[queue].first
  end

  def peek_and_skip(queue)
    @mutex[queue].lock do
      message = @cache[queue].shift
      return message if message

      @cache[queue] = @base.peek_and_skip_batch queue, @size
      @cache[queue].shift
    end
  end

  def skip(queue)
    @cache[queue].shift
    super
  end

  def skip_all(queue)
    @cache.delete queue
    super
  end

  def drop(queue)
    @cache.delete queue
    super
  end

  def cleanup(queue)
    @cache.delete queue
    super
  end
end
