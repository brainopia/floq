class Floq::Plugins::Logger
  include Floq::Plugins::Base

  def initialize(adapter, file)
    super
    @logger = file
  end

  def pull(queue, &block)
    @adapter.pull queue do |message|
      log_around pre: 'pull', post: queue, payload: message do
        block.call message
      end
    end
  end

  def push(queue, data)
    log "push #{queue}", data
    @adapter.push queue, data
  end

  def log(message, *payload)
    @logger.puts Format.with_time Format.block(message, payload)
  end

  def log_around(pre:'', post:'', payload:nil, &block)
    log "#{pre} begin #{post}", payload
    start_time = Time.now
    yield
  ensure
    spent_time = Time.now - start_time
    post += ' ' << Format.duration(spent_time)
    log "#{pre} finish #{post}", payload, *($! && $!.backtrace)
  end

  module Format
    extend self
    EOL = "\n"

    def block(message, payload)
      payload.compact!
      if payload.empty?
        message + EOL*2
      else
        message + EOL << Format.indent(payload) << EOL*2
      end
    end

    def duration(time)
      "[#{time.round 2}]"
    end

    def with_time(message)
      "#{Time.now} -- #{message}"
    end

    def indent(text, offset=4)
      if text.is_a? Array
        text.map {|it| indent it, offset }.join "\n"
      else
        text.to_s.prepend ' '*offset
      end
    end
  end
end
