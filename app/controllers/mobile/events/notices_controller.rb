class Mobile::Events::NoticesController < Mobile::ApplicationController
  layout "mobile/common"
  def index
    @page_title = "模拟炒股赢现金"
  end
end
