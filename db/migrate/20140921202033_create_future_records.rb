class CreateFutureRecords < ActiveRecord::Migration
  def change
    create_table :future_records do |t|
      t.attachment :recording

      t.timestamps
    end
  end
end
