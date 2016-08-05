class CommonUploader < CarrierWave::Uploader::Base
  storage :file

  def cache_dir
    Rails.root.join 'public/upload_tmps'
  end

  def store_dir
    "uploads/commons/#{Date.today.to_s(:db)}"
  end

  def filename
    "#{Time.now.to_s(:number)}_#{rand(100000)}.#{file.extension}" if original_filename.present?
  end

  # def extension_white_list
    
  # end
end