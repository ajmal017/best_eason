# host/uploads/basket_screenshots/1/2132132.jpg => /image_machine/basket/126/23329.jpg
class BasketScreenshotUploader

  # --ignore-ssl-errors=yes
  PHANTOM_BASKET_JS = Rails.root.join("lib", "phantomjs", "basket.js")

  def self.draw(basket_id, timestamp)
    url = "#{host}/mobile/shares/baskets/#{basket_id}/graph" # basket_id, timestamp
    path = get_path(basket_id, timestamp)

    # return path if File.exists?(path)

    # 解决中文字体错误 LC_CTYPE=en_US.UTF-8
    shell = "LC_CTYPE=en_US.UTF-8 phantomjs --ignore-ssl-errors=yes #{PHANTOM_BASKET_JS} #{url} #{path}"
    p shell
    puts `#{shell}`
    return file(basket_id, timestamp)
  end

  def self.get_path(basket_id, timestamp)
    folder = Rails.root.join("public", "uploads", "basket_screenshots", basket_id.to_s)
    FileUtils.mkdir_p(folder)
    "#{folder}/#{timestamp}.jpg"
  end

  def self.host
    # Rails.env.production? ? 'http://localhost' : Setting.host
    'http://localhost' 
  end

  def self.file(basket_id, timestamp)
    Rails.root.join("public", "uploads", "basket_screenshots", basket_id.to_s, "#{timestamp}.jpg")
  end

  def self.url(basket_id, timestamp)
    "#{Setting.html_host}/uploads/basket_screenshots/#{basket_id}/#{timestamp}.jpg"
  end

end