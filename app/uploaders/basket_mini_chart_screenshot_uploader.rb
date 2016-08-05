class BasketMiniChartScreenshotUploader < ScreenshotUploader
  DIR_NAME = "basket_mini_charts"

  def url
    "#{host}/screenshot/baskets/#{basket_id}/mini_chart"
  end

  def path
    folder = Rails.root.join("public", "uploads", DIR_NAME)
    FileUtils.mkdir_p(folder)
    "#{folder}/#{basket_id}.png"
  end

  def file
    Rails.root.join("public", "uploads", DIR_NAME, "#{basket_id}.png")
  end

  def self.url(basket_id)
    "/uploads/#{DIR_NAME}/#{basket_id}.png"
  end

  def phantom_js_path
    Rails.root.join("lib", "phantomjs", "basket_mini_chart.js")
  end
end