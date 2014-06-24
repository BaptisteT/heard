class CreateBlockade < ActiveRecord::Migration
  def change
    create_table :blockades do |t|
      t.integer :blocker_id
      t.integer :blocked_id
      t.timestamps
    end
  end
end
