class Floq
  require_relative 'floq/serializer'
  require_relative 'floq/queues'
  require_relative 'floq/schedulers'
  require_relative 'floq/providers'

  QUEUES = {}

  class << self
    attr_accessor :provider

    def [](name, type=:parallel)
      QUEUES[name.to_sym] ||= Queues.const_get(camelcase type).new name
    end

    def queues
      QUEUES.values
    end

    private

    def camelcase(name)
      name.to_s.split('_').map(&:capitalize).join
    end
  end
end
