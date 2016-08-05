class PhoneBook < ActiveRecord::Base
  belongs_to :user
  has_many :phone_book_items

  def self.upload(params_file, user)

    PhoneBook.transaction do

      pb = PhoneBook.find_or_initialize_by(user_id: user.id)
      pb.update(updated_at: Time.now)

      # 清空phone_book_items记录
      pb.phone_book_items.destroy_all
      file = File.open(params_file[:tempfile].path)
      data =  JSON.parse(file.read.strip.chomp)
      data.each do |d|

        name = d["name"] || ""

        # 记录email数据
        d["email"].each do |email|
          if email =~ /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/
            user_id = User.find_by(email: email).try(:id)
            pb.phone_book_items.create!(user_id: pb.user_id, name: name, item_type: "email", item: email, caishuo_id: user_id)
          end
        end

        # 记录mobile数据
        d["mobile"].each do |mobile|
          if mobile =~ /^((\+86)|(86))?(13)\d{9}$/
            user_id = User.find_by(mobile: mobile).try(:id)
            pb.phone_book_items.create!(user_id: pb.user_id, name: name, item_type: "mobile", item: mobile, caishuo_id: user_id)

          end
        end
      end
      file.close
    end
  end
end
