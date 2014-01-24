class Floq::Schedulers::Base
  attr_reader :options, :queues

  def initialize(options={})
    @options = options
    @queues  = options.delete(:queues) { [] }
  end

  def run
    check_handler
    loop { pull_and_handle }
  end

  def split(count)
    return [self] if count == 1
    raise ArgumentError if count < 1

    split_queues(count).map do |queues|
      dup.tap {|it| it.queues.replace queues }
    end
  end

  private

  def initialize_copy(_)
    @queues = @queues.dup
  end

  # TODO: improve
  def split_queues(worker_count)
    parallel, singular = queues.partition(&:splittable?)
    batch_size = (singular.length / worker_count.to_f).ceil
    splitted_singular = singular.each_slice batch_size
    splitted_singular.map {|slice| slice.concat parallel.map(&:dup) }
  end

  def check_handler
    without_handler = queues.reject(&:handler)
    unless without_handler.empty?
      raise ArgumentError, "Missing handler for #{without_handler}"
    end
  end
end
