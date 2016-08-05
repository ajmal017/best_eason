# Read about factories at https://github.com/thoughtbot/factory_girl
require 'faker'

FactoryGirl.define do
  factory :base_stock do
    symbol { Faker::Lorem.characters(4) }
    ib_symbol 'AAPL'
    ticker 'AAPL'
    data_source 'ib'
    board_lot 1
    qualified true
    stock_type "common"
    ib_id 113
    c_name "苹果"
    exchange "NYSE"
    
    before(:create) do |instance|
      instance.ib_symbol = instance.symbol
      instance.ticker = instance.symbol
    end

    factory :hk_stock do
      ib_id 115
      c_name "神话"
      exchange "SEHK"
    end
    factory :base_stock_appl do
      ib_id 12150119
      exchange "SEHK"
      symbol "AAPL"
      ib_symbol 'AAPL'
      ticker 'AAPL'
    end
    factory :base_stock_yhoo do
      ib_id 12150120
      exchange "SEHK"
      symbol "YHOO"
      ib_symbol 'YHOO'
      ticker 'YHOO'
    end
  end
  
  factory :stock, class: 'BaseStock' do
    symbol { Faker::Lorem.characters(4) }
    ib_symbol { Faker::Lorem.characters(4) }
    data_source 'ib'
    exchange "NYSE"
  end
end
