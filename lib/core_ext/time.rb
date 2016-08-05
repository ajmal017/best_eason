class ActiveSupport::TimeWithZone
  def to_s_full
    self.to_s(:full)
  end
end

class Time
  def to_s_full
    self.to_s(:full)
  end
end
