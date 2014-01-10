class Floq::Plugins::Logger
  include Floq::Plugins::Base

  def initialize(adapter, file)
    super
    @logger = file
  end

  def pull(queue, &block)
    log_around 'pull', queue do
      @adapter.pull queue, &block
    end
  end

  def push(queue, data)
    log "push #{queue}\n#{Format.indent data}"
    @adapter.push queue, data
  end

  def log(message)
    @logger.puts "#{Time.now} -- #{message}"
  end

  def log_around(pre, post='', &block)
    log "#{pre} begin #{post}"
    start_time = Time.now
    yield
  ensure
    spent_time = Time.now - start_time
    log "#{pre} finish #{post} #{Format.status $!}"
  end

  module Format
    extend self

    def status(error)
      if error
        "failure\n" + indent(error.backtrace)
      else
        'success'
      end
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
