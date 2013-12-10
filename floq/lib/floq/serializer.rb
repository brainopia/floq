module Floq::Serializer
  def encode(data)
    Marshal.dump data
  end

  def decode(data)
    Marshal.load data
  end
end
