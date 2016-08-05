module Admin::SuggestStocksHelper
  def suggest_stock_target_url(suggest_stock)
    suggest_stock.id.present? ? admin_suggest_stock_path(suggest_stock) : admin_suggest_stocks_path 
  end
end
