class AddGroupIdToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :group_id, :integer, after: :receiver_id
  end
end
