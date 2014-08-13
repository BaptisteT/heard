class CreateInvitedNumbers < ActiveRecord::Migration
  def change
    create_table :invited_numbers do |t|
      t.string :phone_number
    end
  end
end
