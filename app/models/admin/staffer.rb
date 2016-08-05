class Admin::Staffer < ActiveRecord::Base

  belongs_to :role, class_name: 'Admin::Role'#, counter_cache: true
  has_many :permissions
  # app token
  has_many :api_staffer_tokens
  has_many :p2p_strategies

  devise :database_authenticatable, :validatable, :trackable, :timeoutable, :registerable, :authentication_keys => [:email], password_length: 6..20
  
  #validates :username, presence: true, uniqueness: true

  validates :fullname, presence: {message: "姓名不能为空"}, uniqueness: true
  
  validates :email, presence: {message: "邮箱不能为空"}, uniqueness: true
  
  #validates :encrypted_password, presence: {encrypted_password: "密码不能为空"}

  #hacker for devise, 解决日期格式设置成中文出现的问题
  # def timedout?(last_access)
#     return false if remember_exists_and_not_expired?
#     !timeout_in.nil? && last_access && last_access <= timeout_in.ago
#end

  def valid_for_authentication?
    super and !deleted?
  end

  # 登录后对用户token表的处理
  def make_token(attrs={})
    if self.api_staffer_tokens.present?
      token = self.api_staffer_tokens.first
      token.refresh_self!(attrs)
    else
      self.create_api_staffer_tokens(attrs)
    end
  end

  def create_api_staffer_tokens(attrs={})
    token = ApiStafferToken.new(attrs)
    token.staffer_id = self.id
    token.save
  end

  def self.check_login?(username, password)
    user = self.find_by(username: username)
    (user.present? && user.valid_password?(password)) ? user : nil
  end

  def permissions
    self.role.permissions
  end
  
  protected
  def confirmation_required?
    true
  end

  def email_required?
    false
  end


end
