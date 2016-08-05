module MailHelper
  
  def email_image_tag(source, options = {})
    source = Setting.html_host + source unless source.start_with?('http://')
    html = ""
    html << image_tag(source, options)
    raw html
  end

  def reset_password_url(token)
    Setting.host + reset_password_setting_index_path(reset_password_token: token)
  end

end
