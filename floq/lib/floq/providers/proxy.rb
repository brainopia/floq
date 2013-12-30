class Floq::Providers::Proxy
  def self.intercept(*methods)
    methods.each do |name|
      define_method name do |*args|
        @callback.call name, *args do
          @provider.send name, *args
        end
      end
    end
  end

  intercept :peek, :push, :drop, :skip, :skip_all, :offset,
            :offset!, :total, :peek_and_skip, :confirm,
            :confirmed_offset, :read

  def initialize(provider, &callback)
    @provider = provider
    @callback = callback
  end
end
