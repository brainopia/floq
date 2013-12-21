class Floq::Group
  attr_reader :groups, :schedulers

  def initialize(options={})
    @address    = options.fetch :address, '127.0.0.1'
    @port       = options.fetch :port, 0
    @schedulers = options.delete(:schedulers) { [] }

    listen address, port
    add_system_scheduler
  end

  def run
    raise 'only system scheduler' if schedulers.size == 1
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
    @groups = { location => @access_key }
    @group_queue.push @groups
  end

  def listen(address, port)
    if port.to_i == 0
      auto_port = TCPServer.new address, port
      @port = auto_port.addr[1]
      auto_port.close
    end
  end

  def add_system_scheduler
    @group_queue = Floq[:groups, :event_sourced]
    @group_queue.handle do |updated_groups|
      groups.replace updated_groups
    end

    system = Floq::Schedulers::Periodic.new \
      interval: 10, queues: [ @group_queue ]
    schedulers.unshift system
  end
end
