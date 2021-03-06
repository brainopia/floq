class Floq::Plugins::Logger
  include Floq::Plugins::Base

  def initialize(base, file)
    super
    @logger = file
    @logger.sync = true
  end

  def pull(queue, &block)
    @base.pull queue do |message|
      log_around pre: 'pull', post: queue, payload: message do
        block.call message
      end
    end
  rescue
    log "exception during pull #{queue}", $!.message, $!.backtrace
    raise
  end

  def push(queue, data)
    log "push #{queue}", data
    @base.push queue, data
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
    payload = $! ? [payload, $!.message, *$!.backtrace] : [payload]
    log "#{pre} finish #{post}", *payload
  end

  module Format
    extend self
    EOL = "\n"
    SPACE = ' '

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
        text.to_s + SPACE*offset
      end
    end
  end
end
