class MajiaUser < ActiveRecord::Base
  belongs_to :user

  def create_user
    self.user = User.create(email: email, username: username, password: password, password_confirmation: password, headline: headline,
            gender: gender, province: province, city: city)
    user.build_profile(orientations: orientation_data, concerns: concern_data, duration: duration_data)
    user.save 
    save
  end

  def load_city
    code = rand(10)
    case code
    when 0,1
      self.province, self.city = '11', '北京'
    when 4,5
      self.province, self.city = '13', '上海'
    when 6,7
      self.province, self.city = '44', '深圳'
    when 8,9
      self.province, self.city = '44', '广州'
    else
      self.province, self.city = '33', '杭州'
    end
  end

  def reset_city
    self.load_city
    save
  end

  def zone
    "#{CityInit.get_province(province)} -- #{city}"
  end

  def orientation_indexes
    MajiaUser.get_indexes(orientation)
  end

  def orientation_data
    Hash[Profile::ORIENTATION.keys.zip(orientation.split(","))]
  end

  def orientation_values
    orientation_indexes.map do |i|
      Profile::ORIENTATION.values[i]
    end
  end

  def concern_indexes
    MajiaUser.get_indexes(concern)
  end

  def concern_data
    Hash[Profile::CONCERN.keys.zip(concern.split(","))]
  end

  def concern_values
    concern_indexes.map do |i|
      Profile::CONCERN.values[i]
    end
  end

  def duration_index
    MajiaUser.get_indexes(duration).first
  end

  def duration_data
    duration_index
  end

  def duration_value
    Profile::DURATION[duration_index]
  end



  def self.get_indexes(str)
    result = []
    str.split(",").each_with_index do |num, index|
      result << index if num == '1'
    end
    result
  end



end
