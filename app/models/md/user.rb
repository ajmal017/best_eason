class MD::User

  include Mongoid::Document
  include Mongoid::Timestamps
  # include Mongoid::Attributes::Dynamic
  store_in collection: "users"
  # 内容
  field :username
  field :email
  field :avatar


  mount_uploader :avatar, UserAvatar

  def avatar=(url)
    write_uploader(:avatar, url)
  end


  # def avatar_url
  #   UserAvatar.new(model: self, mounted_as: :avatar).url
  # end

  def pretty_json
    {
      id: id,
      username: username,
      avatar: avatar_url
    }
  end


end