# encoding: utf-8

class ContestPlayerUploader < CarrierWave::Uploader::Base
  def extension_white_list
    %w(csv)
  end
  
  def filename
    "#{Time.now.to_s(:number)}.#{file.extension}" if original_filename.present?
  end
end
