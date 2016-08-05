class SitemapUploader < CarrierWave::Uploader::Base

  storage :file

  def initialize(name, path)
    @name = name
    @path = path
  end

  def store_dir
    @path
  end

  def filename
    @name
  end

  def extension_white_list
    %w(xml gz)
  end

end
