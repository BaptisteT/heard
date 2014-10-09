class FacebookAttributes < ActiveRecord::Migration
  def change
    add_column :users, :fb_id, :string
    add_column :users, :fb_first_name, :string
    add_column :users, :fb_last_name, :string
    add_column :users, :fb_gender, :string
    add_column :users, :fb_locale, :string
  end
end
