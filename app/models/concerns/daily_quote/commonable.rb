module DailyQuote
  module Commonable
    extend ActiveSupport::Concern

    included do 
      alias_attribute :close, :last
      alias_attribute :start_date, :date
      alias_attribute :end_date, :date

      scope :by_base_stock_id, -> (base_stock_id) { where(base_stock_id: base_stock_id) }
      scope :date_with, -> (opts) { gte_date(opts[:start_date]).lte_date(opts[:end_date]) }
      scope :gte_date, -> (date) { where("date >= ?", date) if date.present? }
      scope :lte_date, -> (date) { where("date <= ?", date) if date.present? }
      scope :asc_date, -> { order(date: :asc) }
    end

    def as_json
      {
        "open"       => self.open.to_f, 
        "high"       => self.high.to_f, 
        "low"        => self.low.to_f, 
        "close"      => self.last.to_f,
        "ma5"        => self.ma5.to_f, 
        "ma10"       => self.ma10.to_f, 
        "ma20"       => self.ma20.to_f,
        "ma30"       => self.ma30.to_f,
        "volume"     => self.volume.to_i,
        "date"       => (date.to_time + 8.hours).to_i * 1000,
        "start_date" => self.date.to_s(:db),
        "end_date"   => self.date.to_s(:db)
      }
    end
  end
end
