class Mobile::DownloadsController < Mobile::ApplicationController
  layout false

  def redirect
    response.headers['Expires'] = "Mon, 26 Jul 1997 05:00:00 GMT"
    response.headers['Cache-Control'] = 'max-age=0, no-cache, no-store, must-revalidate'
    
    if request.user_agent and request.user_agent =~ /MicroMessenger/i
      @url = ChannelCode::DEFAULT_APK
    elsif request.user_agent and request.user_agent =~ /iPhone|iPod|iPad|iOS/
      @url = "https://itunes.apple.com/us/app/cai-shuo/id983525941"
    else
      @url = ChannelCode.download(channel, true)
    end
  end
end
