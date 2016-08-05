class Counter < ActiveRecord::Base

  alias_attribute :system, :unread_system_count
  alias_attribute :comment, :unread_comment_count
  alias_attribute :like, :unread_like_count
  alias_attribute :hongbao, :unread_hongbao_count
  alias_attribute :position, :unread_position_count
  alias_attribute :stock_reminder, :unread_stock_reminder_count
  alias_attribute :globle, :unread_globle_count

  def comment_with_like
    self.comment + self.like
  end

  def show_warning?
    [unread_mention_count, comment_with_like, unread_message_count, system, stock_reminder, position, hongbao, globle].map(&:to_i).sum > 0
  end

  def set_hongbao_zero
    update(unread_hongbao_count: 0) if !self.unread_hongbao_count.zero?
  end
end
