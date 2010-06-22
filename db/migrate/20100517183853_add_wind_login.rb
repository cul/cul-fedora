class AddWindLogin < ActiveRecord::Migration
  def self.up

    add_column :users, :wind_login, :string
    add_index :users, :wind_login
  end

  def self.down
    remove_column :users, :wind_login
  end
end
