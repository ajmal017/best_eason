class ActiveDock < ActiveRecord::Base

  validates :name, :description, :dock_date, presence: {message: "不能为空！"}
  validates :short_id, custom_length: {min: 1, max: 30, message: "长度不合法"}, presence: true
  validates :name, :short_id, uniqueness: {message: "不能重复！"}

  validate :json_validates
  def json_validates
    begin
      JSON.parse(self.dock_date)
    rescue JSON::ParserError => e
      self.errors.add(:dock_date,"数据格式有误，请重新录入！")
    end
  end

  def ajax_url
    "#{Setting.host}/ajax/data/events/#{short_id}.json"
  end

end
