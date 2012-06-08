class Date
  def to_milliseconds
    self.to_time.to_i * 1000
  end
end
