class AddEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email, :string, after: :fb_locale
  end
end
