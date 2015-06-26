class CreateInboxes < ActiveRecord::Migration
  def change
    create_table :inboxes do |t|
      t.string :recipient
      t.text :message

      t.timestamps null: false
    end
  end
end
