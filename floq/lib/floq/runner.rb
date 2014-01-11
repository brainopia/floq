class Floq::Runner
  attr_reader :neighbours, :schedulers

  def initialize(options={})
    @address    = options.fetch :address, '127.0.0.1'
    @port       = options.fetch :port, 0
    @schedulers = options.delete(:schedulers) { [] }

    listen @address, @port
    add_system_scheduler
  end

  def run
    # raise 'only system scheduler' if schedulers.size == 1
    publish_location
    run_schedulers
  end

  def location
    "#@address:#@port"
  end

  private

  def run_schedulers
    Thread.abort_on_exception = true
    @schedulers.map do |scheduler|
      Thread.new { scheduler.run }
    end.each(&:join)
  end

  def publish_location
    @access_key = SecureRandom.hex
    @neighbours = { location => @access_key }
    @neighborhood.push @neighbours
  end

  def listen(address, port)
    if port.to_i == 0
      auto_port = TCPServer.new address, port
      @port = auto_port.addr[1]
      auto_port.close
    end
  end

  def add_system_scheduler
    return # not ready to roll

    @neighborhood = Floq[:groups, :event_sourced]
    @neighborhood.handle do |runners|
      neighbours.replace runners
    end

    system = Floq::Schedulers::Periodic.new \
      interval: 10, queues: [ @neighborhood ]
    schedulers.unshift system
  end
end
