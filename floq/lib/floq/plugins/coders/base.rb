class Floq::Plugins::Coders::Base
  include Floq::Plugins::Base

  def offset(queue)
    @adapter.offset(queue).to_i
  end

  def push(queue, message)
    @adapter.push queue, encode(message)
  end

  def peek(queue)
    result = @adapter.peek queue
    decode result if result
  end

  def peek_and_skip(queue)
    result, offset = @adapter.peek_and_skip queue
    [decode(result), offset] if result
  end

  def read(*args)
    (@adapter.read(*args) || []).map &method(:decode)
  end
end
