class AddTextToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :text, :string
  end
end
