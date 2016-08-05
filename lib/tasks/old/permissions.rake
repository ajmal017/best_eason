namespace :permissions do
  desc "初始化权限数据"
  task :init_permission => :environment do
    permissions_id = []
    Admin::Menu.instance[:menu].each do |permission|
      if (permission["name"] == "活动" || permission["name"] == "调查")
        Admin::Permission.new(name: permission["name"],url: "#",father_id: 0).save(validate: false)
        parent = Admin::Permission.last
      else
        parent = Admin::Permission.create(name: permission["name"], url: "#", father_id: 0)
      end
      permissions_id << parent.id
      roles_id = Admin::Role.where(name: permission["roles"]).pluck(:id)
      permission["menus"].each do |m|
        if (m["name"] == "查看短信发送状态" || m["name"] == "查看回复短信内容")
          Admin::Permission.new(name: m["name"], url: m["href"], father_id: parent.id).save(validate: false)
          child = Admin::Permission.last
        else
          child = Admin::Permission.create(name: m["name"], url: m["href"], father_id: parent.id)
        end
        permissions_id << child.id
      end
      permissions_id.each do |p_id|
        if roles_id.size == 1
          Admin::RolePermission.create(role_id: roles_id[0], permission_id: p_id)
        else
          roles_id.each do |r_id|
            Admin::RolePermission.create(role_id: r_id, permission_id: p_id)
          end
        end
      end
      permissions_id = []
      roles_id = []
    end
  end
end