# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

#%w(站务 警示 趋势 历史 Milestone).each do |name|
#  ArticleCategory.find_or_create_by(name: name)
#end

base_stock = BaseStock.create(symbol: '^HSI', name: '恒生指数', stock_type: BaseStock::STOCK_TYPE[:special])
puts '--Loading Data: 恒生指数 --'
Yahoo::Historical::Base.new([base_stock.id]).sync

BaseStock.create(symbol: '^GSPC', name: 'S&P 500', stock_type: BaseStock::STOCK_TYPE[:special], data_source: 'ib', exchange: 'NYSE')
BaseStock.create(symbol: '^IXIC', name: 'NASDAQ Composite', stock_type: BaseStock::STOCK_TYPE[:special], data_source: 'ib', exchange: 'NYSE')
BaseStock.create(symbol: '^DJI', name: 'Dow Jones Industrial Average', stock_type: BaseStock::STOCK_TYPE[:special], data_source: 'ib', exchange: 'NYSE')

stock_attrs = [["usd/hkd", "美元-港元", "HKD=X"], ["usd/cny", "美元-人民币", "CNY=X"], 
               ["hkd/usd", "港元-美元", "HKDUSD=X"], ["cny/usd", "人民币-美元", "CNYUSD=X"], 
               ["hkd/cny", "港元-人民币", "HKDCNY=X"], ["cny/hkd", "人民币-港元", "CNYHKD=X"]]
stock_attrs.each do |name, c_name, symbol|
  BaseStock.create({name: name, c_name: c_name, symbol: symbol, qualified: false, stock_type: 'special'})
end
