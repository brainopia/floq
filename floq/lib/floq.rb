module Floq
  require_relative 'floq/queue'
  require_relative 'floq/plugins'
  require_relative 'floq/schedulers'
  require_relative 'floq/provider'
  require_relative 'floq/runner'

  QUEUES = {}

  class << self
    def [](name, type=:parallel)
      QUEUES[name.to_sym] ||= Queue.new name, Provider.use(:puller, type)
    end

    def queues
      QUEUES.values
    end
  end
end
