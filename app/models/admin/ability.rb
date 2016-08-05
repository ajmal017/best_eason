class Admin::Ability
  include CanCan::Ability
  
  def initialize(current_staffer)
    
    # 超级管理员
    can :manage, :all if current_staffer.admin?

    # 普通管理员可以编辑自己的信息
    can :update, Admin::Staffer do |staffer|
      staffer == current_staffer
    end
   
    can :show, Admin::Staffer do |staffer|
      staffer == current_staffer
    end

    # 市场人员特有的权限
    if current_staffer.role_id == 3
    end

    # Ruby team特有的权限
    if current_staffer.role_id == 4
    end
  end
end
