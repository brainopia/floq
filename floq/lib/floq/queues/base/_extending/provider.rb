class Floq::Queues::Base
  def self.delegate_provider(*methods)
    methods.each do |method|
      class_eval <<-CODE
        def #{method}
          provider.#{method} name
        end
      CODE
    end
  end

  private

  def provider
    Floq.provider
  end
end
