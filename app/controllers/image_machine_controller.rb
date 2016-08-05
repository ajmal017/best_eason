class ImageMachineController < ActionController::Base
  def stock
    # Stock.find(params[params[:stock_id]).class.
    market = $redis.hget('realtime:'+params[:stock_id], 'market')
    if params[:no_cache]
      timestamp = Time.now*1000
    else
      timestamp = "stock/#{market}".camelize.safe_constantize.try(:get_screenshot_key)
    end
    img_path = StockScreenshotUploader.draw(params[:stock_id], timestamp.to_i)
    render_404("对不起，您所访问的页面不存在。", "很抱歉,您访问的图片不存在") and return if img_path.blank?
    send_file img_path, :type => 'image/jpeg', :disposition => 'inline', filename: "#{params[:timestamp]}.jpg"
  end

  def basket
    img_path = BasketScreenshotUploader.draw(params[:basket_id], params[:timestamp].to_i)
    render_404("对不起，您所访问的页面不存在。", "很抱歉,您访问的图片不存在") and return if img_path.blank?
    send_file img_path, :type => 'image/jpeg', :disposition => 'inline', filename: "#{params[:timestamp]}.jpg"
  end
  
  private
  
  def render_404(title, message=nil)
    @title = title
    @message = message || title
    respond_to do |format|
      format.html { render :template => '/shared/error_simple', :status => :not_found}
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end
  
  
  

end