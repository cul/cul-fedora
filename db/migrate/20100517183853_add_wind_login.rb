class AddWindLogin < ActiveRecord::Migration
  def self.up

    add_column :users, :wind_login, :string
    add_column :users, :persistence_token, :string
    add_index :users, :wind_login
    add_index :users, :persistence_token
  end

  def self.down
    remove_column :users, :wind_login
    remove_column :users, :persistence_token
  end
end
