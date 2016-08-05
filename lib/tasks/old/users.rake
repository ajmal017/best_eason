namespace :users do
  desc "创建系统用户"
  task :create_system_user => :environment do
    User.create(email: "system@caishuo.com", username: "system", password: "caishuo7ujm8ik,")
    puts "end"
  end

  desc "以前注册的用户自动关注财蜜，并发欢迎私信"
  task :old_user_follow_caishuo_user => :environment do
    caishuo_user = User.find_by_id(Setting.auto_followed_user_id)
    User.find_each do |user|
      next if user.id == caishuo_user.id
      puts user.id
      user.follow_user(caishuo_user)
      User.send_welcome_message(caishuo_user, user)
    end
  end
end