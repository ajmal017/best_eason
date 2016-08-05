# 后台管理菜单配置
class Admin::Menu
  include Singleton

  # 初始化配置文件
  def initialize(file_path="#{Rails.root}/config/menu.yml")
    @file_path = file_path
    load_conf
  end
  
  # 转发调用
  def [](key)
    load_conf if Rails.env.development?
    @menus[key.to_sym]
  end

  def self.menus
    instance[:menu]
  end

  def self.find_by_role(role_abbrev)
    menus.find_all{|menu| menu["roles"].include?(role_abbrev.to_s)} || []
  end

  private

  # 载入配置文件
  def load_conf
    @menus = YAML.load_file(@file_path)
    symbolize_keys!(@menus)
  end

  def symbolize_keys!(obj)
    return unless obj.is_a?(Hash)
    obj.symbolize_keys!
    obj.each_value {|v| symbolize_keys!(v) }
  end
end
