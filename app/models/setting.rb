class Setting < Settingslogic
  source "#{Rails.root}/config/config.yml"
  namespace Rails.env

  load! if Rails.env.development?

  # default
  # zaker
  # caishuo
  def self.apk_url(channel=:default)
    Setting.app.apk[channel] || Setting.app.apk.default
  end

end
