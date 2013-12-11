require 'spec_helper'

describe Floq::Queues do
  let(:name)     { :test_queue }
  let(:message)  {{ foo: :bar }}
  let(:messages) { Floq::Providers::Memory::MESSAGES }

  before { queue.drop }

  def invoke(count=1, &block)
    counter = double
    counter.should_receive(:invoked).exactly(count).times
    proc do |*args|
      counter.invoked
      block.call *args if block
    end
  end

  shared_examples_for :queue do
    it 'push' do
      queue.push message
      messages[queue.name].should have(1).message
    end

    context 'empty queue' do
      its(:offset) { 0 }
      its(:peek) { }

      it 'pull should not be invoked' do
        queue.pull &invoke(0)
      end

      it 'pull should not change offset' do
        queue.pull {}
        queue.offset.should == 0
      end
    end

    context 'queue with a message' do
      before do
        queue.push message
      end

      its(:offset) { 0 }
      its(:peek) { message }

      it 'pull and change offset' do
        queue.pull &invoke {|it| it == message }
        queue.offset.should == 1
      end
    end
  end

  context 'singular queue' do
    let(:queue) { Floq::Queues::Singular.new name }
    it_should_behave_like :queue
  end
end