class KlineMaCache < ActiveRecord::Base
  serialize :ma5
  serialize :ma10
  serialize :ma20
  serialize :ma30

  enum category: [:daily, :weekly, :monthly]
end
