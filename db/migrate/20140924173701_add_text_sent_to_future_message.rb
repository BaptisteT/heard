class AddTextSentToFutureMessage < ActiveRecord::Migration
  def change
    add_column :future_messages, :text_sent, :boolean, default: false
  end
end
