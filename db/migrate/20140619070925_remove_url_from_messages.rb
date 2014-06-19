class RemoveUrlFromMessages < ActiveRecord::Migration
  def change
    remove_column :messages, :url, :string
  end
end
