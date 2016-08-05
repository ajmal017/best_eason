class DataCheck::PositionArchive
  @queue = :data_check
  
  def self.perform
    date = Date.yesterday
    cn_count = ::PositionArchive.where(archive_date: date).cn.count
    us_count = ::PositionArchive.where(archive_date: date).us.count
    hk_count = ::PositionArchive.where(archive_date: date).hk.count
    
    msg = "数据检查:持仓归档:#{date.to_s(:db)}:A股数量#{cn_count}:美股数量:#{us_count}:港股数量#{hk_count}"

    DataCheck::Notice.perform(msg)
  end

end
