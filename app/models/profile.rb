class Profile < ActiveRecord::Base

  # 性别
  MALE = true
  FEMALE = false
  GENDERS = {"男" => true, "女" => false}.invert

  # 投资方向
  ORIENTATION = {a: "沪深", us: "美股", hk: "港股", option: "期权", bonds: "债券", funds: "基金", financial: "理财产品", p2p: "P2P", futures: "期货"}

  # 投资关注
  CONCERN = {fundamentals: "基本面", technical: "技术面", message: "消息", macroscopic: "宏观", trend: "趋势", value: "价值"}

  # 持仓多久
  DURATION = {"短线 （< 1月）" => 0, "中长期（1月到1年）" => 1, "长期（> 1年）" => 2}.invert

  validates :intro, custom_length: {max: 140, message: "长度不合法"}, sensitive: true, allow_nil: true


  belongs_to :user

  # 能力圈
  has_many :taggings, as: :taggable, class_name: 'Tagging', dependent: :destroy
  has_many :tags, -> { uniq }, through: :taggings

  scope :of_user, -> (user_id) {where(user_id: user_id)}

  accepts_nested_attributes_for :taggings, allow_destroy: :true, reject_if: :all_blank

  validates :user_id, presence: true

  # 使用序列化存储
  serialize :orientations, Hash
  serialize :concerns, Hash

  def orientation
    ORIENTATION.slice(*(self.orientations.select {|k,v| v == "1"}.keys.map(&:to_sym))).values.join("、")
  end

  def concern
    CONCERN.slice(*(self.concerns.select {|k,v| v == "1"}.keys.map(&:to_sym))).values.join("、")
  end

  def period
    DURATION[self.duration]
  end

  def sex
    GENDERS[gender]
  end

  def location
    l = "#{CityInit.get_province(self.province)}#{city}"
    l.present? ? l : nil
  end

  def tagged_by?(tag_id)
    Tagging.exists?(taggable: self, tag_id: tag_id)
  end

  def update_profile(profile_params)
    ActiveRecord::Base.transaction do
      self.taggings.delete_all if profile_params[:taggings_attributes]
      self.update!(profile_params)
    end
  end
end
