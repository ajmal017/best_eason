namespace :categories do
  desc "修改类别"
  task :edit => :environment do
    c = Category.find_by(name: "热门主题")
    c.update(name: "热门组合") if c
    Category.find_or_create_by(name: "每日要闻", code: "PonyReport")
    puts "end"
  end
end