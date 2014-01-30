class Floq::Provider
  def chain
    @chain ||= compile
  end

  private

  def reset_chain
    @chain = nil
  end

  def compile
    raise unless valid?
    hierarchy.inject do |app, middleware|
      middleware.call app
    end
  end
end
