class CreateP2pStrategies < ActiveRecord::Migration
  def change
    create_table :p2p_strategies do |t|
      t.string :base_type
      t.integer :staffer_id
      t.references :mentionable, :polymorphic => true
      t.string :change_type
      t.decimal :weight, :precision => 13, :scale => 4, default: 1

      t.timestamps
    end
  end
end
