class Rest::P2pProductsController < Rest::BaseController
  def index
    present P2pService.products
  end
end
