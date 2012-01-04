class CreateItemTypes < ActiveRecord::Migration
  def self.up
	create_table :item_types, {} do |t|
		t.column :name,	:string
		t.column :is_income, :boolean, :default=>false
		t.column :is_active, :boolean, :default=>true
	end
  end

  def self.down
    drop_table :item_types
  end
end

