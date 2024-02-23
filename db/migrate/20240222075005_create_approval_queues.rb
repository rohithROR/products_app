class CreateApprovalQueues < ActiveRecord::Migration[7.0]
  def change
    create_table :approval_queues do |t|
      t.integer :product_id
      t.timestamps
    end
  end
end
