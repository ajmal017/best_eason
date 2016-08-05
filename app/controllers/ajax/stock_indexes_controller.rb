class Ajax::StockIndexesController < Ajax::ApplicationController
=begin
  { 
    :djs=>{"index"=>"17279.74", "change"=>"13.75", "percent"=>"0.08"}, 
    :nasdq=>{"index"=>"4579.79", "change"=>"-13.64", "percent"=>"-0.30"}, 
    :bp=>{"index"=>"2010.40", "change"=>"-0.96", "percent"=>"-0.05"}, 
    :hs=>{"index"=>"24334.650", "change"=>"137.440", "percent"=>"0.570"}
  }
=end
  def index
    render json: ::StockIndex.all
  end
end