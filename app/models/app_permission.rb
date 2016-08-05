class AppPermission < ActiveRecord::Base
  belongs_to :user

  AppPermission.column_names.select{|n| n =~ /^all_/ }.each do |name|
    define_method "#{name}_real" do |current_user|
      self.user.try(:friend?, current_user.try(:id)) || send(name)
    end
  end

end
