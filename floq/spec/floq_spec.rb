require 'spec_helper'

describe Floq do
  context 'unset #adapter' do
    around do |example|
      adapter = Floq.adapter
      Floq.adapter = nil
      example.run
      Floq.adapter = adapter
    end

    it 'raises an exception' do
      expect { Floq.adapter }.to raise_exception
    end
  end
end
