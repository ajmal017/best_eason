class SmsReport < ActiveRecord::Base
  scope :created_at_gte, -> (date_str) { date_str.present? ? where("created_at >= ?", Date.parse(date_str)) : all}
  scope :created_at_lte, -> (date_str) { date_str.present? ? where("created_at <= ?", Date.parse(date_str) + 1) : all}
end
