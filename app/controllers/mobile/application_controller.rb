class Mobile::ApplicationController < ApplicationController
  skip_before_action :mobile_redirect
  skip_after_filter :store_location
  before_action :set_unique_id

  layout false

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    redirect_to mobile_link(mobile_login_path)
  end

  def auth_url
    return_url(mobile_link(mobile_login_path))
  end

  def set_ga_label
    @ga_label = request.user_agent && request.user_agent =~ /iPhone|iPod|iPad|iOS/ ? "IOS" : "Android"
  end

  def old_app_version?
    !request.headers["HTTP_X_CLIENT_VERSION"].present?
  end

  def incre_app_channel_views
    channel_code = ChannelCode.find_channel(params[:channel])
    return unless channel_code
    incre_fields = [:views_count]
    incre_fields.push(:uv_count) if cookies[:cv_ts].to_i < Date.today.at_beginning_of_day.to_i
    if cookies[:cv_ts].to_i < 30.minutes.ago.to_i
      cookies[:cv_ts] = {value: Time.now.to_i, expires: 24.hours.from_now, domain: :all}
      incre_fields.push(:visits_count)
    end
    channel_code.try(:incre_views, incre_fields)
  end

  def app_uuid
    current_user.try(:id) || (cookies["X-SN-Code"].blank? ? nil : "uuid_#{cookies["X-SN-Code"]}") || (cookies[:cs_rid].blank? ? nil : "csid_#{cookies[:cs_rid]}")
  end

  def hide_page_title_postfix
    @hide_page_title_postfix = true
  end

  def hide_gtm
    @hide_gtm = true
  end

  def hide_top_bar
    @hide_top_bar = true
  end

  private

  def set_pc_link(url_path)
    @pc_link = "#{Setting.host}#{url_path}?fr=mobile"
  end

  # key: cs_rid caishuo random id
  def set_unique_id
    cookies[:cs_rid] ||= {
      value: SecureRandom.uuid,
      expires: 1.year.from_now,
      domain: '.caishuo.com'
    }
  end

end
