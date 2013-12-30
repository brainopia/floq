require 'spec_helper'

describe Floq::Adapters::Proxy do
  let(:log) { [] }
  let(:actual_provider) { Floq::Adapters::Memory }

  subject do
    described_class.new actual_provider do |*args, &action|
      result = action.call
      log.push [*args, result]
    end
  end

  it 'should intercept calls' do
    subject.push   :queue, data: :foo
    subject.peek   :queue
    subject.offset :queue
    subject.skip   :queue
    log.should == [
      [:push,   :queue, {:data=>:foo}, [{:data=>:foo}]],
      [:peek,   :queue, {:data=>:foo}],
      [:offset, :queue, 0],
      [:skip,   :queue, 1]
    ]
  end
end
