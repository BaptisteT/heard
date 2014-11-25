class AddTextPositionToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :text_position, :float
  end
end
