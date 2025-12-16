class RemoveCheckedInFromRegistrations < ActiveRecord::Migration[7.1]
  def change
    remove_column :registrations, :checked_in, :boolean
  end
end
