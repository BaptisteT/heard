class AddTimestampsToGroups < ActiveRecord::Migration
  def change
    change_table(:groups) { |t| t.timestamps }
  end
end
