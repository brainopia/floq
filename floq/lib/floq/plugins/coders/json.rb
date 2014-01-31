require 'json'

class Floq::Plugins::Coders::Json < Floq::Plugins::Coders::Base
  def encode(data)
    JSON data
  end

  def decode(data)
    JSON data
  end
end
