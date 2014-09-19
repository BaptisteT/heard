class CreateProspects < ActiveRecord::Migration
  def change
    create_table :prospects do |t|
      t.string :phone_number
      t.string :first_name
      t.string :last_name
      t.integer :contacts_count
      t.string :contact_ids
      t.string :facebook_id

      t.timestamps
    end
  end
end
