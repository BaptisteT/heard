class CreateMappedContacts < ActiveRecord::Migration
  def change
    create_table :mapped_contacts do |t|
      t.integer :user_id

      t.timestamps
    end
  end
end
