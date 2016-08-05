class Suggest < ActiveRecord::Base
  belongs_to :article
  
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h

  mount_uploader :image, SuggestUploader
  
  has_one :temp_image, as: :resource, class_name: 'Upload::Suggest', dependent: :destroy

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

end
