class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.references :organizer, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description, null: false
      t.string :location, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.integer :capacity
      t.string :status, null: false, default: "published"
      t.datetime :registration_open_from
      t.datetime :registration_open_until
      t.integer :registrations_count, default: 0

      t.timestamps
    end
  end
end
