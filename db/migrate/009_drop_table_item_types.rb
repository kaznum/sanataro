class DropTableItemTypes < ActiveRecord::Migration
  def self.up
    drop_table :item_types
  end

  def self.down
    create_table :item_types do |t|
      t.string :name
      t.boolean :is_income, :default=>false
      t.boolean :is_active, :default=>true
      t.integer :order_no
      t.integer :user_id
    end
  end
end
