class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :comments, [:event_id, :created_at]
  end
end

