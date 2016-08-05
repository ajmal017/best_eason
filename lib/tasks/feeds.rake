namespace :feeds do
  desc "初始化feeds position"
  task :init_position => :environment do
    user_ids = MD::Feed.distinct(:user_id)
    user_ids.each do |uid|
      puts uid
      MD::Feed.where(user_id: uid).asc(:created_at).each_with_index do |feed, index|
        feed.update(position: index)
      end
    end
    puts "end"
  end

end
