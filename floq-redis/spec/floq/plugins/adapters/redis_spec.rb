require 'spec_helper'

describe Floq::Plugins::Adapters::Redis do
  let(:queue) { :test_queue }

  before do
    subject.drop queue
  end

  context 'empty' do
    it 'peek' do
      subject.peek(queue).should be_nil
    end

    it 'offset' do
      subject.offset(queue).should == 0
    end

    it 'total' do
      subject.total(queue).should == 0
    end

    it 'skip' do
      subject.skip queue
      subject.offset(queue).should == 1
      subject.peek(queue).should be_nil
    end

    it 'skip_all' do
      subject.skip_all queue
      subject.offset(queue).should == 0
    end

    it 'push' do
      subject.push(queue, 'foobar')
      subject.peek(queue).should == 'foobar'
    end

    it 'peek_and_skip' do
      subject.peek_and_skip(queue).should == [nil, 0]
      subject.offset(queue).should == 0
    end
  end

  context 'filled' do
    let(:prefill) { 3 }

    before do
      prefill.times do |i|
        subject.push queue, "message_#{i}"
      end
    end

    it 'peek' do
      subject.peek(queue).should == 'message_0'
      subject.offset(queue).should == 0
    end

    it 'total' do
      subject.total(queue).should == prefill
    end

    it 'skip' do
      subject.skip queue
      subject.peek(queue).should == 'message_1'
      subject.offset(queue).should == 1
    end

    it 'skip_all' do
      subject.skip_all queue
      subject.peek(queue).should be_nil
      subject.offset(queue).should == prefill
    end

    it 'confirm' do
      subject.confirm(queue, 1)
      confirm_key = subject.send(:confirm_key, queue)
      subject.pool.with do |client|
        client.lindex(confirm_key, 0).should == '1'
      end
    end

    it 'peek_and_skip' do
      subject.skip queue
      subject.peek_and_skip(queue).should == ['message_1', 1]
      subject.offset(queue).should == 2
    end
  end
end
