class AddTextAndBodyToComments < ActiveRecord::Migration
  def change
    # 原始内容
    add_column :comments, :text, :text
    # 渲染之后的html全文
    add_column :comments, :body, :text
  end
end
