class CreateInitialTables < ActiveRecord::Migration
  def change
    create_table :users do |t|
    	t.string :phone_number
    	t.string :first_name
    	t.string :last_name
    	t.string :app_version
    	t.string :api_version
    	t.string :push_token
        t.string :auth_token

		t.attachment :profile_picture

    	t.timestamps
    end

    create_table :messages do |t|
    	t.integer :sender_id
    	t.integer :receiver_id
    	t.boolean :opened
        
        t.attachment :record

    	t.timestamps
    end
  end
end
