class AddRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :role_sym, :null => false
      t.timestamps
    end

    add_index :roles, :role_sym, :unique => true
  end

  def self.down
    drop_table :roles
  end
end
