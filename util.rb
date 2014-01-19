class Util
  # time to microsecond. if time is nil, return to now time
  # @param [Time] time
  # @return [Number] microsecond
  def self.time_to_microsecond(time=nil)
    time ||= Time.now
    (time.to_f * 1_000_000).to_i
  end

  # time to microsecond. if time is nil, return to now time
  # @param [Number] microsecond
  # @return [Number] time
  def self.microsecond_to_time(microsecond)
    Time.at (microsecond / 1_000_000).to_i
  end

end