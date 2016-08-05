class CalculateBasketIndex
  @queue = :calculate_basket_index
  
  def self.perform(market)
    market = market.to_sym
    date_str = (market == :us ? (Date.today - 1) : Date.today).to_s(:db)
    Basket.where(market: market).where(type: ["Basket::Normal", "Basket::Custom"]).completed_and_archived.select(:id).find_each do |basket|
      Resque.enqueue(BasketIndexQueue, basket.id, date_str)
    end

    stock_class = {
      us: 'Stock::Us',
      cn: 'Stock::Cn',
      hk: 'Stock::Hk'
    }
    BaseStock.where(type: stock_class[market]).find_each do |bs|
      Resque.enqueue(StockQueue, bs.id)
    end
    
    Basket.set_baskets_hot_ranks
  end
end
