require 'spec_helper'

describe Floq::Queue do
  let(:name)     { :test_queue }
  let(:message)  {{ foo: :bar }}

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
    let(:queue) { Floq[name, :singular] }
    it_should_behave_like :queue
  end

  context 'parallel queue' do
    let(:queue) { Floq[name, :parallel] }
    it_should_behave_like :queue
  end
end
