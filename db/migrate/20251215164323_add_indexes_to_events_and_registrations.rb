class AddIndexesToEventsAndRegistrations < ActiveRecord::Migration[7.1]
  def change
    # Index for filtering events by status and date (commonly queried together)
    add_index :events, [:status, :starts_at] unless index_exists?(:events, [:status, :starts_at])
    
    # Index for filtering registrations by status (for check-in queries)
    add_index :registrations, :status unless index_exists?(:registrations, :status)
  end
end
