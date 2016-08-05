namespace :caishuo do
  
  desc "notification migrate"
  task :notification_update => :environment do

    Notification::Comment.find_each{ |nc| nc.save } 
    Notification::Like.find_each{ |nl| nl.save }

    puts "=========END=========="
  end

  desc "notification migrate"
  task :generate_notification_title => :environment do

    Notification::System.where("content like '%未通过%'").update_all(title: "组合创建失败")
    Notification::System.where("content not like '%未通过%'").update_all(title: "组合创建成功")
    Notification::Position.all.each{|p| p.update(title: "组合\"#{p.mentionable.try(:title)}\"") }
    Notification::StockReminder.all.each{|p| p.update(title: "$#{p.mentionable.try(:c_name) || p.mentionable.try(:name)}(#{p.mentionable.try(:symbol)})$") }

    puts "=========END=========="
  end
end
