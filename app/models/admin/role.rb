class Admin::Role < ActiveRecord::Base
  has_many :staffers, dependent: :nullify
  has_many :role_permissions,dependent: :destroy
  has_many :permissions, :through => :role_permissions,dependent: :destroy
  validates :name, :presence => {:message => "角色名称不能为空！"},
    			   :uniqueness => {:message => "此角色已存在，请重新输入！"},
    			   :length => {:minimum => 2, :maximum => 20, :message => "长度不正确[建议长度2-20]"}
end