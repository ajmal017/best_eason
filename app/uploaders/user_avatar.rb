class UserAvatar < BaseUploader

  def store_dir
    "uploads/user/#{mounted_as}/#{model.id}"
  end

  version :normal do
    process :resize_to_fit => [450, nil]
  end

  version :small do
    process :crop
    process :resize_to_fill => [50, 50]
  end

  version :large do
    process :crop
    process :resize_to_fill => [180, 180]
  end

  def crop
    return unless model.cropping?
    if model.cropping?
      resize_to_fit(450, nil)
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
    %w(jpg jpeg png gif)
  end

  def default_url
    ActionController::Base.helpers.asset_path("/images/v3/userEditLogo.png")
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
