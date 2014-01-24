class Floq::Runner
  attr_reader :neighbours, :schedulers

  def initialize(options={})
    @address    = options.fetch :address, '127.0.0.1'
    @port       = options.fetch :port, 0
    @schedulers = options.delete(:schedulers) { [] }
    @split      = options.delete(:split) { 1 }

    # listen @address, @port
    # add_system_scheduler # TODO: prevent splitting
  end

  def run
    # raise 'only system scheduler' if schedulers.size == 1
    # publish_location
    setup_signal_traps
    run_schedulers
  end

  def location
    "#@address:#@port"
  end

  private

  def run_schedulers
    Thread.abort_on_exception = true
    @schedulers
      .flat_map {|scheduler| scheduler.split @split }
      .map {|scheduler| Thread.new { scheduler.run }}
      .each(&:join)
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
    @neighborhood = Floq[:groups, :event_sourced]
    @neighborhood.handle do |runners|
      neighbours.replace runners
    end

    system = Floq::Schedulers::Periodic.new \
      interval: 10, queues: [ @neighborhood ]
    schedulers.unshift system
  end

  def setup_signal_traps
    trap :INT do
      exit
    end
  end
end
