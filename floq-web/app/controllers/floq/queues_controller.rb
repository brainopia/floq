class Floq::QueuesController < ActionController::Base
  before_filter :set_queue, only: %w(show destroy)

  def index
    @queues = Floq.queues
  end

  def show
  end

  def destroy
    @queue.drop
    redirect_to :back
  end

  private

  def set_queue
    @queue = Floq[params[:id]]
  end
end
