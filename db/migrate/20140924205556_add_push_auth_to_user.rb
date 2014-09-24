class AddPushAuthToUser < ActiveRecord::Migration
  def change
    add_column :users, :push_auth, :boolean, after: :micro_auth
  end
end
