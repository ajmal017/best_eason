# host/uploads/stock_screenshots/1/2132132.png => /image_machine/basket/126/23329.png
class StockScreenshotUploader

  # --ignore-ssl-errors=yes
  PHANTOM_STOCK_JS = Rails.root.join("lib", "phantomjs", "stock.js")

  def self.draw(stock_id, timestamp)
    url = "#{host}/mobile/shares/stocks/#{stock_id}/graph" # stock_id, timestamp
    puts url
    path = get_path(stock_id, timestamp)

    return path if File.exists?(path)

    # 解决中文字体错误 LC_CTYPE=en_US.UTF-8
    shell = "LC_CTYPE=en_US.UTF-8 phantomjs --ignore-ssl-errors=yes #{PHANTOM_STOCK_JS} #{url} #{path}"
    puts shell
    puts `#{shell}`
    return file(stock_id, timestamp)
  end

  def self.get_path(stock_id, timestamp)
    folder = Rails.root.join("public", "uploads", "stock_screenshots", stock_id.to_s)
    FileUtils.mkdir_p(folder)
    "#{folder}/#{timestamp}.png"
  end

  def self.host
    # Rails.env.production? ? 'http://localhost' : Setting.host
    "http://localhost"
  end

  def self.file(stock_id, timestamp)
    Rails.root.join("public", "uploads", "stock_screenshots", stock_id.to_s, "#{timestamp}.png")
  end

  def self.url(stock_id, timestamp)
    "#{Setting.html_host}/image_machine/stock/#{stock_id}/latest.png"
  end

end