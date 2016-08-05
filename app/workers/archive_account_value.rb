class ArchiveAccountValue
  @queue = :daily_archive
  
  def self.perform(date = nil)
    AccountValueArchive.sync(date || Date.yesterday)
  end

end
