class SyncContestBouns
  @queue = :sync_contest_bouns
  
  def self.perform(contest_id)
    RestClient.trading.pt.asset(contest_id)
  end
end
