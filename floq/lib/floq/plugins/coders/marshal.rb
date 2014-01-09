class Floq::Plugins::Coders::Marshal < Floq::Plugins::Coders::Base
  def encode(data)
    Marshal.dump data
  end

  def decode(data)
    Marshal.load data
  end
end
