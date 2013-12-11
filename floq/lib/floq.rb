class Floq
  require_relative 'floq/serializer'
  require_relative 'floq/queues'
  require_relative 'floq/schedulers'
  require_relative 'floq/providers'

  QUEUES = {}

  class << self
    attr_accessor :provider

    def [](name)
      QUEUES[name] ||= Queues::Parallel.new name
    end

    def queues
      QUEUES.values
    end
  end
end
