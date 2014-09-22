class CreateFutureMessages < ActiveRecord::Migration
  def change
    create_table :future_messages do |t|
      t.integer :sender_id
      t.string :receiver_number
      t.integer :future_record_id

      t.timestamps
    end

    add_column :messages, :future, :boolean, default: false

    remove_column :prospects, :first_name
    remove_column :prospects, :last_name

    add_index :prospects, :phone_number, :unique => true
    add_index :future_messages, :receiver_number, :unique => false
  end
end
