class AddRetrieveContactsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :retrieve_contacts, :boolean, default: false
  end
end
