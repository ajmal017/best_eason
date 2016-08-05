class Admin::FeedsController < Admin::ApplicationController
  respond_to :html, :xls

  before_action :find_feed_hub, only: [:toggle_hub_state, :hub_weight, :push_hub, :confirm_push_hub]

  # Feed控制台
  def index
    # @page_title = "Feed管理"
    # @feeds = ::MD::Feed.where(:recommend_type.ne => 'private')
    # @feeds = @feeds.where(time_rule: params[:time_rule].to_i) if params[:time_rule].present?
    # @feeds = @feeds.where(recommend_type: params[:recommend_type]) if params[:recommend_type].present?

    # @feeds = @feeds.desc(:created_at).limit(50)
    render text: "作废的后台功能"
  end

  def auto
    ::MD::FeedHub.toggle_auto_status
    respond_to do |format|
      format.html { redirect_to action: :hub }
      format.js
    end
  end
  
  def create
    feedable_obj = params[:class_name].constantize.find(params[:id])
    feedable_obj.publish_to_feed_hub
    render json: {status: true}
  end


  def push_filters
    MD::FeedRecommendFilter.publish_to_feed(params[:id])
  end

  def filters
    @page_title = "Filter数据列表"
  end


  def hub
    @page_title = "Feed推荐池"
    @feed_categories = ::MD::FeedCategory.content.to_a

    @feed_hubs = ::MD::FeedHub.or({:expired_at.gt => Time.now}, {expired_at: nil})

    @feed_hubs = @feed_hubs.where(recommend_category: params[:recommend_category]) if params[:recommend_category].present?
    
    if params[:time_rule] == "now"
      @feed_hubs = @feed_hubs.where(:time_rule.in => MD::FeedRule::TimeRule.get_rule) 
    elsif params[:time_rule].present?
      @feed_hubs = @feed_hubs.where(time_rule:  params[:time_rule].to_i) 
    end

    case params[:pics].to_s
    when "yes"
      @feed_hubs = @feed_hubs.where(:pics.nin => [nil, []])
    when "no"
      @feed_hubs = @feed_hubs.where(:pics.in => [nil, []])
    end


    @feed_hubs = @feed_hubs.where(recommend_type: params[:recommend_type]) if params[:recommend_type].present?
    @feed_hubs = @feed_hubs.where(title: Regexp.new(params[:title].strip)) if params[:title].to_s.present?
    @feed_hubs = @feed_hubs.where(weight: params[:weight]) if params[:weight].present?
    if params[:date].present?
      @feed_hubs = @feed_hubs.where(:created_at.gte => params[:date], :created_at.lte => "#{params[:date]} 23:59:59").asc(:created_at)
    else
      @feed_hubs = @feed_hubs.desc(:weight, :created_at)
    end

    @feed_hubs = @feed_hubs.page(params[:page]) if params[:format] != "xls"
    respond_with @feed_hubs
  end

  # 置顶Feed
  def fixed
    @feed_hub = ::MD::Feed::Banner.get_banner(true)
    @page_title = "置顶Feed设置"
  end

  def fixed_action
    params[:feed][:status] = nil if params[:feed].blank? or params[:feed][:status].blank?
    ::MD::Feed::Banner.set_banner(params[:feed])
    redirect_to "/admin/feeds/fixed", notice: "修改成功"
  end

  # 规则页面
  def rule
    @page_title = "Feed规则说明"
  end

  def content_rule
    @page_title = "内容规则"
  end

  def time_rules
    @time_rules = ::MD::FeedRule::TimeRule.all
    render layout: !request.xhr?
  end


  def hub_show
    @feed_hub = ::MD::FeedHub.find(params[:id])
    redirect_to @feed_hub.source_url
  end

  def hub_imgs
    @feed_hub = ::MD::FeedHub.find(params[:id]) rescue nil
    render layout: false
  end


  def history
    @page_title = "测试: 取旧Feed"
    @feeds = ::MD::Feed.search_feeds_for_down(params[:user_id].to_i).to_a
  end


  def fresh
    @page_title = "测试: 推荐新Feed"
    @feeds = ::MD::FeedHub.search(params[:user_id], params[:uuid]).to_a
  end
  
  def toggle_hub_state
    @feed_hub.toggle_state!
  end

  def hub_weight
    status = @feed_hub.reset_weight(params[:weight].to_i)
    render json: {status: status, weight: @feed_hub.weight}
  end

  def push_hub
    @page_title = "Push消息"
    ids = [56816, 56832, 12429, 56670, 12586, 1001, 1008, 1009]
    @users = User.where(id: ids).select(:id, :username, :email)
    @emails = @users.map(&:email)
    @push_logs = PushLog.desc.includes(:staffer).first(10)
    @feed_push_logs = PushLog.where(@feed_hub.jpush_params).desc
  end

  def confirm_push_hub
    push_log_params = @feed_hub.jpush_params.merge({receiver: params[:receiver], content: params[:content], password: params[:password], staffer_id: current_admin_staffer.id})
    @push_log = PushLog.create(push_log_params)
  end

  private
  def find_feed_hub
    @feed_hub = ::MD::FeedHub.find(params[:id])
  end

end
