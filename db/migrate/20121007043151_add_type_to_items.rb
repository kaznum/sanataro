class AddTypeToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :type, :string
    Item.update_all({type: "Adjustment"}, {adjustment: true})
    Item.update_all({type: "GeneralItem"}, {adjustment: false})
    remove_column :items, :adjustment
  end

  def self.down
    add_column :items, :adjustment, :boolean
    Item.update_all({adjustment: true}, {type: "Adjustment"})
    Item.update_all({adjustment: false}, {type: "GeneralItem"})
    remove_column :items, :type
  end
end

