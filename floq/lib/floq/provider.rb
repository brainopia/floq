class Floq::Provider
  require_relative 'provider/_compile_chain'
  require_relative 'provider/_use_plugins'

  def self.default
    @default ||= new.tap do |it|
      it.use! :puller,  :parallel
      it.use! :rescuer, :simple
      it.use! :encoder, :marshal
    end
  end

  def initialize
    @plugins = {}
    wrap :helpers, Floq::Plugins::Helpers
  end

  def hierarchy
    @plugins.values_at(
      :adapter,
      :encoder,
      :puller,
      :logger,
      :rescuer,
      :helpers
    ).compact
  end

  def valid?
    @plugins.values_at(:adapter, :encoder, :puller).all?
  end

  def get(type)
    @plugins[type.to_sym]
  end

  def reset!(type)
    @plugins[type.to_sym] = nil
    reset_chain
    self
  end

  def reset(type)
    clone.reset! type
  end

  private

  def set(type, value)
    @plugins[type.to_sym] = value
  end

  def wrap(type, target, *args)
    set type, if type == :adapter
      target.new *args
    else
      ->(adapter) { target.new adapter, *args }
    end
  end
end
