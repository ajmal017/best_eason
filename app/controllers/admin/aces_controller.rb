class Admin::AcesController < Admin::ApplicationController
  def index
    @page_title = "高手"
    @aces = Ace.all
  end

  def update_all
    params[:ace].each do |p|
      Ace.new(p).save
    end
    redirect_to "/admin/aces"
  end

  def edit_all
    @page_title = "修改高手"
    @aces = Ace.all
  end

end
