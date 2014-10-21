class AddGroupIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :group_id, :integer, after: :receiver_id
  end
end
