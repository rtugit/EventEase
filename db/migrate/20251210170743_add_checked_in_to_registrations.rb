class AddCheckedInToRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :checked_in, :boolean
  end
end
