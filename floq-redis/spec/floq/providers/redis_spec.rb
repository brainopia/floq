require 'spec_helper'

describe Floq::Providers::Redis do
  let(:queue) { :test_queue }
  subject { described_class }

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
  end

  context 'filled' do
    let(:prefill) { 3 }

    before do
      prefill.times do |i|
        subject.push queue, i
      end
    end

    it 'peek' do
      subject.peek(queue).should == '0'
      subject.offset(queue).should == 0
    end

    it 'total' do
      subject.total(queue).should == prefill
    end

    it 'skip' do
      subject.skip queue
      subject.peek(queue).should == '1'
      subject.offset(queue).should == 1
    end

    it 'skip_all' do
      subject.skip_all queue
      subject.peek(queue).should be_nil
      subject.offset(queue).should == prefill
    end
  end
end
