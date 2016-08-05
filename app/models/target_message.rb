class TargetMessage < ActiveRecord::Base
  validates :content, presence: {message: "内容不能为空"}
  validates :target, presence: {message: "目标用户不能为空"}
  def displayed_target
    target_before_type_cast.is_a?(String) ? target_before_type_cast.split(',').map(&:to_i).join("\n") : target_before_type_cast
  end

  # attr_reader :queue
  include Redis::Objects
  counter :r_succ_counter
  counter :r_fail_counter

  # QUEUE = :target_message
  #
  # def initialize(opts={})
  #   self.instance_variable_set(:@queue, QUEUE)
  #   super
  # end
  #
  # def perform
  #   caishuo_user = User.find(Setting.auto_followed_user_id)
  #   if target == "all"
  #     User.all.each do |user|
  #       Resque.enqueue(MessageAddWorker, caishuo_user.id, user.id, id)
  #       #MessageAddWorker.perform(caishuo_user.id, user.id, id)
  #     end
  #   else
  #     target.split(",").each do |user_id|
  #       begin
  #         Resque.enqueue(MessageAddWorker, caishuo_user.id, user_id, id)
  #         #MessageAddWorker.perform(caishuo_user.id, user_id, id)
  #       rescue
  #         fail_counter.increment
  #         Rails.logger.error "给ID是#{id}的用户发私信失败"
  #       end
  #     end
  #   end
  # end

  def target_counter
    target == "all"? User.all.size : target_before_type_cast.split(",").length
  end

end
