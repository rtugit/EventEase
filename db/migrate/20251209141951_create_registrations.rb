class CreateRegistrations < ActiveRecord::Migration[7.1]
  def change
    create_table :registrations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, foreign_key: true, null: true
      t.string :email, null: false
      t.string :name
      t.string :status, null: false, default: "registered"
      t.datetime :check_in_at
      t.datetime :cancelled_at

      t.timestamps
    end
    add_index :registrations, [:event_id, :email], unique: true
  end
end
