class DropTableItemTypes < ActiveRecord::Migration
  def self.up
    drop_table :item_types
  end

  def self.down
    create_table :item_types, {} do |t|
      t.column :name, :string
      t.column :is_income, :boolean, :default=>false
      t.column :is_active, :boolean, :default=>true
      t.column :item_types, :order_no, :integer
      t.column :item_types, :user_id, :integer
    end
  end
end
