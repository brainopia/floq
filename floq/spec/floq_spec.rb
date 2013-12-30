require 'spec_helper'

describe Floq do
  context 'missing provider' do
    around do |example|
      provider = Floq.provider
      Floq.provider = nil
      example.run
      Floq.provider = provider
    end

    it '#provider raises an exception' do
      expect { Floq.provider }.to raise_exception
    end
  end
end
