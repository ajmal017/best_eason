class CreateFollows < ActiveRecord::Migration
  def change
    create_table :follows do |t|
      t.integer :user_id
      t.integer :following_id
      t.boolean :friend, default: false # 相互关注
      t.boolean :read, default: false # 是否已经查看
      
      t.references :followable, polymorphic: {limit: 16}

      t.timestamps
    end

    add_index :follows, [:followable_type, :followable_id]
    add_index :follows, :user_id
    add_index :follows, :following_id
  end
end
