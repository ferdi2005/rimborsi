class RenameExpenseAttachmentToAttachments < ActiveRecord::Migration[7.2]
  def up
    ActiveStorage::Attachment.where(record_type: "Expense", name: "attachment")
                             .update_all(name: "attachments")
  end

  def down
    ActiveStorage::Attachment.where(record_type: "Expense", name: "attachments")
                             .update_all(name: "attachment")
  end
end
