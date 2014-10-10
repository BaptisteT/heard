class AddConvertedToFutureMessage < ActiveRecord::Migration
  def change
    add_column :future_messages, :converted, :boolean
  end
end
