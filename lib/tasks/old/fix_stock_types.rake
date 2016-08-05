namespace :caishuo do
  desc 'fix stock types'
  task :fix_stock_types => :environment do 
    puts "====begin===="
    BaseStock.where(type: nil, stock_type: nil).where(exchange: 'SEHK').update_all(type: 'Stock::Hk')
    
    BaseStock.where(type: nil, stock_type: nil).where(exchange: ['NASDAQ', 'NYSE']).update_all(type: 'Stock::Us')
    
    BaseStock.where(type: nil, stock_type: nil).update_all(type: 'Stock::Cn')
    puts "====end====="
  end
end
