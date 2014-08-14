class AddTimestampsToInvitedNumbers < ActiveRecord::Migration
  def change_table
    add_column(:invited_numbers, :created_at, :datetime)
    add_column(:invited_numbers, :updated_at, :datetime)
  end
end
