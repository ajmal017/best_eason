class SyncCa
  @queue = :ca

  def self.perform
    (Date.today..Date.today + 7.days).each do |date|
      CaGrab::Dividend.new(date).fetch
      CaGrab::Split.new(date).fetch
      CaGrab::OriginDividend.new(date).fetch
      CaGrab::OriginSplit.new(date).fetch
    end

    CaGrab::Hk.new.fetch
  end

end
