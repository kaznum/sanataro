class AddTypeToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :type, :string
    Item.where(adjustment: true).update_all(type: "Adjustment")
    Item.where(adjustment: false).update_all(type: "GeneralItem")
    remove_column :items, :adjustment
  end

  def self.down
    add_column :items, :adjustment, :boolean
    Item.where(type: "Adjustment").update_all(adjustment: true)
    Item.where(type: "GeneralItem").update_all(adjustment: false)
    remove_column :items, :type
  end
end

