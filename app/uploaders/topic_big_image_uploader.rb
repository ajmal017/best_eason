class TopicBigImageUploader < BaseUploader
  process :quality => 100
  
  version :normal do
    process :resize_to_limit => [800, nil]
  end

  version :large do
    process :crop
    process :resize_to_fill => [700, 394]
  end

  version :small do
    process :crop
    process :resize_to_fill => [350, 197]
  end
  
  def crop
    return unless model.cropping?
    if model.cropping?
      resize_to_limit(700, nil)
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
    %w(jpg jpeg png gif bmp)
  end

  def default_url
    ActionController::Base.helpers.asset_path("/images/v3/hotspot_pic1.jpg")
  end

  def filename
    @name ||= "#{md5}.#{file.extension}" if original_filename.present?
  end

  protected
  def md5
    var = :"@#{mounted_as}_md5"
    model.instance_variable_get(var) or model.instance_variable_set(var, ::Digest::MD5.file(current_path).hexdigest)
  end

end
