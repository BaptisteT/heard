class AddMicroAndContactToUser < ActiveRecord::Migration
  def change
    add_column :users, :contact_auth, :boolean, default: false
    add_column :users, :micro_auth, :boolean
  end
end
