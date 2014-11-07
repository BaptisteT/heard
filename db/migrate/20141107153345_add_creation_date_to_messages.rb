class AddCreationDateToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :creation_date, :integer, default: 0
  end
end
