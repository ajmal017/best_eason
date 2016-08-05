class CreateTopicBaskets < ActiveRecord::Migration
  def change
    create_table :topic_baskets do |t|
      t.integer :topic_id
      t.integer :basket_id
      t.boolean :tagged, default: false

      t.timestamps
    end

    add_index :topic_baskets, [:topic_id, :basket_id], unique: true
  end
end