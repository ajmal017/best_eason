class PortfolioArchive < ActiveRecord::Base

  def self.daily_generate(exchange_name, date)
    Portfolio.includes(:base_stock).send("with_#{exchange_name}").references(:base_stock).find_in_batches(batch_size: 3000) do |ps|
      imports = ps.map do |p|
        attrs = p.attributes.merge(archive_date: date).stringify_keys.except("id", "created_at", "updated_at")
        self.new(attrs)
      end
      
      self.import(imports, on_duplicate_key_update: %w(position currency symbol contract_id account_name updated_by market_price market_value average_cost unrealized_pnl realized_pnl))
    end
  end

end
