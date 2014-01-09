class Floq::Provider
  attr_reader :adapter, :coder, :puller, :rescuer

  Plugins = Floq::Plugins

  def self.parallel
    default.dup.tap do |it|
      it.puller = Plugins::Pullers::Parallel
    end
  end

  def self.singular
    default.dup.tap do |it|
      it.puller = Plugins::Pullers::Singular
    end
  end

  def self.default
    @default ||= new.tap do |it|
      it.puller  = Plugins::Pullers::Parallel
      it.rescuer = Plugins::Rescuers::DelayedRetry
      it.coder   = Plugins::Coders::Marshal
    end
  end

  def chain
    @chain ||= compile
  end

  def adapter=(value)
    @adapter = value
    reset_chain
  end

  def coder=(value)
    @coder = value
    reset_chain
  end

  def puller=(value)
    @puller = value
    reset_chain
  end

  def rescuer=(value)
    @rescuer = value
    reset_chain
  end

  private

  def reset_chain
    @chain = nil
  end

  def valid?
    adapter and coder and puller
  end

  def hierarchy
    [adapter, coder, puller, Floq::Plugins::Helpers, rescuer].compact
  end

  def compile
    raise unless valid?
    hierarchy.inject {|app, middleware| middleware.new app }
  end
end
