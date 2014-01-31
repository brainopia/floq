require 'json'

class Floq::Plugins::Encoders::Json < Floq::Plugins::Encoders::Base
  def encode(data)
    JSON data
  end

  def decode(data)
    JSON data
  end
end
