class Admin::Permission < ActiveRecord::Base
  
  
  validates :url, :presence => {:message => "不能为空"},
            :length => {:minimum => 1, :maximum => 255, :message => "长度不正确[建议长度1-255]"}
  validates :name, :presence => {:message => "不能为空"},
    			  :uniqueness => {:message => "不能重复"},
    			  :length => {:minimum => 2, :maximum => 20, :message => "长度不正确[建议长度2-20]"}

  has_many :role_permissions, dependent: :destroy
  has_many :roles, :through => :role_permissions,dependent: :destroy
  has_many :childrens, -> {includes(:staffer)}, class_name: "Admin::Permission", foreign_key: :father_id, dependent: :destroy

  belongs_to :staffer
  belongs_to :father, class_name: "Admin::Permission", foreign_key: :father_id

  scope :children, -> { where.not(father_id: 0) }
  scope :father, -> { where(father_id: 0) }

end