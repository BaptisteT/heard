class AddInitialMessagesNbAndTextReceivedNbToUser < ActiveRecord::Migration
  def change
    add_column :users, :initial_messages_nb, :integer
    add_column :users, :text_received_nb, :integer
  end
end
