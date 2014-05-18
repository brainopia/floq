class Floq::Plugins::Encoders::Base
  include Floq::Plugins::Base

  def offset(queue)
    @base.offset(queue).to_i
  end

  def push(queue, message)
    @base.push queue, encode(message)
  end

  def peek(queue)
    result = @base.peek queue
    decode result if result
  end

  def peek_and_skip(queue)
    result, offset = @base.peek_and_skip queue
    [decode(result), offset] if result
  end

  def recover(queue)
    result, offset = @base.recover queue
    [decode(result), offset] if result
  end

  def read(*args)
    (@base.read(*args) || []).map &method(:decode)
  end
end
