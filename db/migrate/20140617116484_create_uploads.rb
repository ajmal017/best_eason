class CreateUploads < ActiveRecord::Migration
  def change
    # 上传表
    create_table :uploads do |t|
      t.references :user
      t.string :type
      t.string :image

      t.integer :resource_id
      t.string :resource_type

      t.timestamps
    end

    add_index :uploads, :user_id
    add_index :uploads, :type
    add_index :uploads, [:resource_id, :resource_type]
  end
end
