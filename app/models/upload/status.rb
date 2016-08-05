class Upload::Status < Upload::Base
  mount_uploader :image, StatusUploader
  
  def to_upload
    {
      id: id,
      url: image.url,
      thumb_url: image.url(:normal)
    }
  end
end
