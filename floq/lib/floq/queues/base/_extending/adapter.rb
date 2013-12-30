class Floq::Queues::Base
  def self.delegate_adapter(*methods)
    methods.each do |method|
      class_eval <<-CODE
        def #{method}
          adapter.#{method} name
        end
      CODE
    end
  end

  private

  def adapter
    Floq.adapter
  end
end
