class AddRecipientToInbox < ActiveRecord::Migration
  def change
    add_column :inboxes, :recipient, :string
  end
end
