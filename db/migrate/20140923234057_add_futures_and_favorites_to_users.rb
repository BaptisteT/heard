class AddFuturesAndFavoritesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :futures, :integer
    add_column :users, :favorites, :integer
  end
end
