namespace :messages do
  desc "矫正一些由于直接删除会话导致未读数量不一致的数据"
  task :adjust_user_unread_messages_count => :environment do
    messages = Message.where(user_talk_id: nil, read: false)
    user_ids = messages.map(&:receiver_id).uniq
    messages.update_all(read: true)
    user_ids.each do |user_id|
      puts user_id
      Message.adjust_counter!(user_id)
    end
  end


  desc "发系统消息给用户"
  task :send_messages => :environment do
    content = <<-HTML
      财说2.0版本全新上线！一款像女朋友一样体贴的炒股管家^_^ 
      新增私人定制服务，投资趋势更精准，实时交易更安全，惊喜很多，用后便知：<a href="https://www.caishuo.com/app?from=messages">https://www.caishuo.com/app?from=messages</a>
      猜指数大赛火热进行中，展现你实力的时候到了，10台手机任性送！<a href="https://www.caishuo.com/articles/672">https://www.caishuo.com/articles/672</a>
    HTML
    # user_ids = [6127, 11523, 1342, 10619, 4066, 1014, 1697, 11344, 11746, 7130, 2222, 10404, 7813, 7587, 7960, 1006, 1111, 11604, 10996, 11387, 4269, 5355, 7581, 3601, 10637, 1453, 2459, 3932, 1414, 11825, 4312, 7669, 3325, 11787, 1701, 11816, 1030, 1001, 12389, 12393, 11428, 7889, 11320, 7544, 1007, 12423, 1370, 2028, 11835, 1449, 12116, 3759, 2759, 4892, 6608, 4548, 10909, 6768, 7324, 5170, 8152, 2349, 7350, 2993, 7035, 11815, 3452, 8247, 4940, 4938, 11509, 11924, 4280, 1017, 1837, 1019, 5144, 12112, 11716, 2925, 1869, 3817, 6564, 4080, 7622, 10954, 10068, 2062, 12533, 7730, 12521, 11026, 12542, 11711, 6980, 7905, 12566, 1533, 12511, 1389, 11961, 7638, 5558, 4467, 4101, 6185, 7898, 7357, 7279, 1387, 12763, 12803, 8282, 12837, 12838, 12875, 12897, 2096, 13029, 13083, 1877, 11679, 13148, 13157, 11366, 13193, 1020, 13209, 13170, 11843, 11769, 8271, 11157, 7113, 5788, 12570, 6191, 5997, 6712, 2248, 11347, 11271, 12756, 12829, 12847, 12851, 12858, 3859, 12904, 10392]

    sender_id = 1075  # 财蜜
    User.find_each do |u|
      Message.add(sender_id, u.id, content)
      puts u.id
    end
  end

  desc "发送手机短信"
  task :send_mobile => :environment do
    # msg = "脱胎换骨，为你炒股。财说APP全新改版，只为更懂你。立刻升级猜大盘指数，还能赢坚果手机。刚送出一台，你还等啥。http://m.caishuo.com/app"
    # mobiles = User.where("mobile is not null").pluck(:mobile)

    # mobiles.each do |mobile|
    msg = "历时三个月，财说全新改版，只为更懂你。现在更新参与猜大盘活动还能赢坚果手机哦！http://m.caishuo.com/app"
    User.where("mobile is not null").select(:id, :mobile).find_in_batches do |group|
      group.in_groups_of(50, false).each do |users|
        mobiles = users.map(&:mobile)
        uids = users.map(&:id)
        begin
          Sms.send_sms(mobile, msg)
        rescue => e
          Rails.logger.error("SMS Failed: #{mobiles}")
        end
        puts "sended #{uids} #{mobiles}"
      end
    end
  end
end