class ArticleUploader < BaseUploader
  process :quality => 100
  
  version :normal do
    process :resize_to_limit => [500, nil]
  end

  version :large do
    process :crop
    process :resize_to_fill => [300, 204]
  end

  version :small do
    process :crop
    process :resize_to_fill => [150, 120]
  end
  
  def crop
    return unless model.cropping?
    if model.cropping?
      resize_to_limit(500, nil)
      manipulate! do |img|
        x = model.crop_x.to_i
        y = model.crop_y.to_i
        w = model.crop_w.to_i
        h = model.crop_h.to_i
        img.crop("#{w}x#{h}+#{x}+#{y}")
        img
      end
    end
  end
  
  def extension_white_list
    %w(jpg jpeg gif png bmp)
  end
  
  def default_url
    ActionController::Base.helpers.asset_path("/images/v2/logo.png")
  end

  def filename
    @name ||= "#{md5}.#{file.extension}" if original_filename.present?
  end

  process :resize_to_limit => [550, nil]

  protected
  def md5
    var = :"@#{mounted_as}_md5"
    model.instance_variable_get(var) or model.instance_variable_set(var, ::Digest::MD5.file(current_path).hexdigest)
  end

end
