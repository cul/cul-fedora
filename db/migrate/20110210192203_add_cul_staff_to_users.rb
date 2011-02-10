class AddCulStaffToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :cul_staff, :boolean, :default => false
  end

  def self.down
    remove_column :users, :cul_staff
  end
end
