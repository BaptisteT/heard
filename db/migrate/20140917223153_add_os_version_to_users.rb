class AddOsVersionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :os_version, :string
  end
end
