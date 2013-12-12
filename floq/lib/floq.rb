class Floq
  require_relative 'floq/serializer'
  require_relative 'floq/queues'
  require_relative 'floq/schedulers'
  require_relative 'floq/providers'

  QUEUES = {}

  class << self
    attr_accessor :provider

    def [](name, type=:parallel)
      QUEUES[name] ||= Queues.const_get(type.capitalize).new name
    end

    def queues
      QUEUES.values
    end
  end
end
