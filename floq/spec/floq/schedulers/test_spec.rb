require 'spec_helper'

describe Floq::Schedulers::Test do
  let(:mail) { Hash.new {|hash,key| hash[key] = [] }}
  let(:queues) { queues_for *queue_names }
  let(:queue_names) { [:queue_1, :queue_2] }
  subject { described_class.new queues: queues }

  before { subject.drop }

  def queues_for(*names)
    names.map do |name|
      queue = Floq[name]
      queue.handle {|data| mail[name] << data }
      queue
    end
  end

  its(:pushed) { [] }

  it 'should run without messages' do
    expect { subject.run }.not_to raise_exception
  end

  it 'should handle a simple message' do
    Floq[:queue_1].push :a_message
    subject.run
    mail.should == { queue_1: [ :a_message ] }
  end

  it 'should handle nested messages' do
    Floq[:queue_1].handle {|data| Floq[:queue_2].push data }
    Floq[:queue_1].push :routed_message
    subject.run
    mail.should == { queue_2: [ :routed_message ] }
  end
end
