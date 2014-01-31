class Floq::Plugins::Encoders::Marshal < Floq::Plugins::Encoders::Base
  def encode(data)
    Marshal.dump data
  end

  def decode(data)
    Marshal.load data
  end
end
