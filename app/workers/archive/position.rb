class Archive::Position
  @queue = :daily_archive
  
  # market :us, :hk, :cn
  # date_str 2015-08-13
  def self.perform(market, date_str)
    raise 'date_str must be a string' unless date_str.is_a?(String)

    PositionArchive.daily_generate(market.to_sym, Date.parse(date_str))
  end

end
