class AddPhoneBooks < ActiveRecord::Migration
  def change
    create_table :phone_books do |t|
      t.integer :user_id     # 上传者id
      t.integer :items_count # 上传通讯录记录数量

      t.timestamps null: false
    end

    create_table :phone_book_items do |t|
      t.integer :user_id     # 上传者id

      # 以下为通讯录用户信息
      t.string  :name        # 用户名称
      t.integer :phone_book_id # 关联phone_books
      t.string  :item_type, null: false, default: "mobile"   # 数据类型 email or mobile
      t.string  :item        # 数据
      t.integer  :caishuo_id  # 匹配财说用户的id

      t.timestamps null: false
    end
  end
end
