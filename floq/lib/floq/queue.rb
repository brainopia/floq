class Floq::Queue
  attr_reader :label, :name

  def initialize(label, provider=Provider.default)
    raise ArgumentError unless label

    @label    = label
    @name     = "floq-#{label}"
    @provider = provider
  end

  def method_missing(method, *args, &block)
    @provider.chain.send method, name, *args, &block
  end
end
