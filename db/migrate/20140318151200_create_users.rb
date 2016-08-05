class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email,            :null => false
      t.string :username,         :null => true
      t.string :unconfirmed_email
      t.string :avatar    #头像
      t.string :logo      #临时头像
      t.boolean :gender
      
      # 城市
      t.integer :province, :limit => 5
      t.string  :city, :limit => 50
      
      # 简介
      t.string :biography

      # 邀请人
      t.integer :invitation_id
      t.integer :invitation_limit, default: 0

      t.boolean :admin
      t.boolean :is_company_user, default: false
      
      # 帳號是否鎖定
      t.boolean :available, default: true
      
      # counter cache
      t.integer :followings_count, default: 0
      t.integer :followers_count, default: 0
      t.integer :baskets_count, default: 0
      t.integer :confirmation_count, default: 0

      # 密码
      t.string :encrypted_password
      
      # 重置密码
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      
      t.datetime :remember_created_at

      # 激活
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.integer :confirmation_count
      
      t.timestamps
    end
    
    add_index :users, :followings_count
    add_index :users, :followers_count
    add_index :users, :baskets_count

    add_index :users, :email, unique: true
    add_index :users, :username
    add_index :users, :province
    add_index :users, :city

    add_index :users, :confirmation_token
    add_index :users, :reset_password_token
  end
end
