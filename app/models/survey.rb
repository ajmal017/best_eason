class Survey < ActiveRecord::Base
  validates :user_phone, uniqueness: true, presence: true
  validates :user_name, :user_gender, :q1_1, :q4, :q5, presence: true
  validate :check_q3, :check_q1

  Q1 = ["头条", "投组合", "选个股"]
  Q3 = ["国内外资讯", "技术指标分析", "热点实时评论", "操作心得"]

  def q3_content
    q3_content = ""
    [self.q3_1, self.q3_2, self.q3_3, self.q3_4].reject(&:blank?).map { |i| q3_content << Q3[i] }
    q3_content + " " + self.q3_5
  end

  def at_least_one
    if [self.q3_1, self.q3_2, self.q3_3, self.q3_4].reject(&:blank?).size == 0
      false
    else
      true
    end
  end

  def q1_12
    if q1_1 == 3 && q1_2.blank?
      false
    else
      true
    end
  end

  private
  def check_q3
    errors.add(:q3, "至少选一个") unless at_least_one
  end

  def check_q1
    errors.add(:q1, "单选按钮问题") unless q1_12
  end

end
