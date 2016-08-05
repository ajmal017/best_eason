module Mongoable
  extend ActiveSupport::Concern

  included do
    # 同步保存
    after_commit :mongo_save, on: [:create, :update]
    # 同步删除
    after_commit :mongo_destroy, on: [:destroy]
    
  end

  def mongo_class
    "MD::#{self.class.name}".constantize
  end
  
  
  def mongo_save
    mongo_class.find_or_initialize_by(id: id).update(attributes.slice(*mongo_class.attribute_names), validate: false)
  end
  
  def mongo_destroy
    return true if mongo.nil?
    mongo.destroy
  end
  
  # 取对象的mongodb对象
  def mongo
    #mongo_class.find(id) #avoid "Mongoid::Errors::DocumentNotFound" error
    mongo_class.where(id: id).first
  end

end