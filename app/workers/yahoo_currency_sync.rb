class YahooCurrencySync
  @queue = :fundament_sync
  
  def self.perform
    Yahoo::Currency::Base.new.sync
  end
end
