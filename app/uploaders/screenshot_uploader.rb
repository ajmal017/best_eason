# host/uploads/basket_screenshots/1/2132132.jpg => /image_machine/basket/126/23329.jpg
class ScreenshotUploader

  def initialize(opts)
    @opts = opts
  end

  def self.draw(opts)
    self.new(opts).draw
  end

  def draw
    shell = "LC_CTYPE=en_US.UTF-8 phantomjs --ignore-ssl-errors=yes #{phantom_js_path} #{url} #{path}"
    puts `#{shell}`
    file
  end

  def url
    raise "请重写url方法"
  end

  def path
    raise "请重写get_path方法"
  end

  def file
    raise "请重写file方法"
  end

  def host
    Rails.env.production? ? 'http://www.caishuo.com' : 'http://localhost'
  end

  def phantom_js_path
    Rails.root.join("lib", "phantomjs", "base.js")
  end

  def method_missing(method, *args, &block)
    @opts[method.to_sym]
  end

end