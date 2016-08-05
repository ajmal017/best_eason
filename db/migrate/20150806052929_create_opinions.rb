class CreateOpinions < ActiveRecord::Migration
  def change
    create_table :opinions do |t|
      t.references :user, index: true
      t.references :opinionable, polymorphic: {limit: 16}
      t.integer :opinion
      t.datetime :post_time

      t.timestamps
    end

    add_index :opinions, [:opinionable_type, :opinionable_id]
    add_index :opinions, [:opinionable_type, :opinionable_id, :opinion], name: :idx_opinions_of_opinion_opinionable
  end
end
