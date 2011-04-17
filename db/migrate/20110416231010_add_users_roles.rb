class AddUsersRoles < ActiveRecord::Migration
  def self.up
    create_table :roles_users, :id => false do |t|
      t.column :user_id, :integer, :null => false
      t.column :role_id, :integer, :null => false
    end
    add_index :roles_users, :user_id, :unique => false
    add_index :roles_users, :role_id, :unique => false
  end

  def self.down
    drop_table :roles_users
  end
end
