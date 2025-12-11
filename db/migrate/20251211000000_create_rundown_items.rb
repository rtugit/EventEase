class CreateRundownItems < ActiveRecord::Migration[7.1]
  def change
    create_table :rundown_items do |t|
      t.references :event, null: false, foreign_key: true
      t.string :heading
      t.text :description
      t.integer :position

      t.timestamps
    end

    add_index :rundown_items, [:event_id, :position]
  end
end

