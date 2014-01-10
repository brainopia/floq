class Floq::Provider
  require_relative 'provider/_compile_chain'
  require_relative 'provider/_use_plugins'

  def self.default
    @default ||= new.tap do |it|
      it.use! :puller,  :parallel
      it.use! :rescuer, :delayed_retry
      it.use! :coder,   :marshal
    end
  end

  def initialize
    @plugins = {}
    wrap :helpers, Floq::Plugins::Helpers
  end

  def hierarchy
    @plugins.values_at(
      :adapter,
      :coder,
      :puller,
      :logger,
      :helpers,
      :rescuer
    ).compact
  end

  def valid?
    @plugins.values_at(:adapter, :coder, :puller).all?
  end

  def get(type)
    @plugins[type.to_sym]
  end

  private

  def set(type, value)
    @plugins[type.to_sym] = value
  end

  def wrap(type, klass, *args)
    set type, ->(adapter) do
      if type == :adapter
        klass.new *args
      else
        klass.new adapter, *args
      end
    end
  end
end
