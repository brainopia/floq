require 'spec_helper'

describe Floq::Schedulers::Test do
  let(:mail) { Hash.new {|hash,key| hash[key] = [] }}
  let(:queues) { queues_for queue_names }
  subject { described_class.new queues }

  before { subject }

  def queues_for(*names)
    names.map do |name|
      queue = Floq[name]
      queue.handle {|data| mail[name] << data }
      queue
    end
  end

  context 'one queue' do
    let(:queue_names) { :queue }

    its(:pushed) { [] }

    it 'should run without messages' do
      expect { subject.run }.not_to raise_exception
    end

    it 'should handle simple message' do
      Floq[:queue].push :a_message
      subject.run
      mail.should == { queue: [ :a_message ] }
    end
  end
end
