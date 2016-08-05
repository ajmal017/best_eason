module Screenshot
  # 通过通送网页url去抓取截图
  def catch_scrrenshot(url)
    response = Typhoeus.post("#{Setting.img_upload_host}/upload/upimgNet.htm", body: { fileUrl: url, isScreen: true})
    body = response.body.force_encoding("utf-8")
    $screenshot_logger.info("response status => #{response.success?}, response code => #{response.code}, body => #{body}")
    response_body = JSON.parse(body) rescue {}
    response.success? && response_body["success"] ? "#{Setting.cdn_host}/#{response_body["path"]}" : nil
  end
end
