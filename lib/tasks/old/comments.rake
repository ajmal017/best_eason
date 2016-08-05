namespace :comments do
  desc "评论改版,迁移评论数据"
  task :load => :environment do
    Comment.where(top_commentable_id: nil).each do |comment|
      puts "********非法数据****#{comment.id}*****" if comment.commentable_id.blank?
      # 如果被评论的对象是一个评论的话
      if comment.replyable_type == "Comment"

        replyed_comment = Comment.find(comment.replyable_id)
        if replyed_comment.replyable_type == "Comment"
          top_comment = Comment.find(replyed_comment.replyable_id)
          puts top_comment.replyable_type

          # 对两级评论的评论
          attrs = {
            top_commentable_id: top_comment.replyable_id,
            top_commentable_type: top_comment.replyable_type,
            commentable_ids: "#{top_comment.id},#{replyed_comment.id},"
          }
          comment.update(attrs)
        else
          # 对一级评论的评论
          attrs = {
            top_commentable_id: replyed_comment.replyable_id,
            top_commentable_type: replyed_comment.replyable_type,
            commentable_ids: "#{replyed_comment.id},"
          }
          comment.update(attrs)
          puts replyed_comment.replyable_type
        end
      else
        # 一级评论
        attrs = {
          top_commentable_id: comment.replyable_id,
          top_commentable_type: comment.replyable_type
        }

        comment.update(attrs)
      end
    end

  end

  desc "重置评论数量"
  task :reset_count => :environment do
    Comment.find_each do |c| 
      puts c.id
      begin
      c.send(:reset_comments_count)
      rescue Exception => e
        puts "#####{c.id}"
      end
    end
  end

  desc "迁移content"
  task :migrate_content => :environment do
    Comment.find_each do |c|
      puts c.id
      text = ActionController::Base.helpers.strip_tags(c.content)
      c.text = text unless c.text
      c.body = c.content unless c.body
      c.save(validate: false)
      puts "#{c.id} ERROR" unless c.valid?
    end
  end

  desc "截取content"
  task :truncate_content => :environment do
    Comment.find_each do |c|
      next if c.text.blank?
      puts c.id
      c.content = Caishuo::Utils::Text.truncate_emoji_text(c.text.truncate(100))
      c.save(validate: false)
    end
  end

  desc "fix message"
  task :fix_message => :environment do
    Comment.find_each do |c|
      c.send(:set_root_replyed)
      c.send(:set_full_message)
      c.send(:set_root_replyed_body)
      c.save(validate: false)
      puts c.id unless c.valid?
    end
  end

  desc "generate mobile content"
  task :generate_mobile_content => :environment do
    Comment.find_each do |c|
      c.set_mobile_body
      c.save(validate: false)
    end
  end
end
