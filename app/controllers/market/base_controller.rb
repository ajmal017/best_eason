class Market::BaseController < ActionController::Base
  layout "market"
  helper_method :channel

  def channel
  end

end