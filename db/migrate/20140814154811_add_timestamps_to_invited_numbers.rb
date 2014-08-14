class AddTimestampsToInvitedNumbers < ActiveRecord::Migration
  def change
      change_table(:invited_numbers) { |t| t.timestamps }
  end
end