class AddAttachmentToMessages < ActiveRecord::Migration
  def self.up
    change_table :messages do |t|
      t.attachment :record
    end
  end

  def self.down
    drop_attached_file :messages, :record
  end
end
