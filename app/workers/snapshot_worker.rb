class SnapshotWorker
  @queue = :snapshot

  def self.perform(url)
    system "curl '#{url}'"
  end
end