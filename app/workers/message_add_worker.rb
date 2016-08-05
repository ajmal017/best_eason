class MessageAddWorker
  @queue = :message_add

  def self.perform(target_message_id)
    target_message = TargetMessage.find(target_message_id)
    caishuo_user = User.find(Setting.auto_followed_user_id)
    target = target_message.target_before_type_cast
    if target == "all"
      User.all.each do |user|
        begin
          if Message.add(caishuo_user.id, user.id, target_message.content)
            target_message.r_succ_counter.increment
          else
            target_message.r_fail_counter.increment
          end
        rescue
          target_message.r_fail_counter.increment
          Rails.logger.error "给ID是#{user.id}的用户发私信失败"
        end
      end
    else
      target.split(",").each do |user_id|
        begin
          if Message.add(caishuo_user.id, user_id, target_message.content)
            target_message.r_succ_counter.increment
          else
            target_message.r_fail_counter.increment
          end
        rescue
          target_message.r_fail_counter.increment
          Rails.logger.error "给ID是#{id}的用户发私信失败"
        end
      end
    end
    target_message.update(succ_count: target_message.r_succ_counter.value)
    target_message.update(fail_count: target_message.r_fail_counter.value)
  end


end
