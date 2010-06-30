class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :first_name, :length => 30
      t.string :last_name, :length => 40
      t.boolean :admin
      t.string :login, :unique=>true, :null=>false
      t.string :wind_login, :unique => true
      t.string :email, :unique=>true
      t.string :crypted_password
      t.string :persistence_token
      t.integer :login_count, :default => 0, :null => false
      t.text :last_search_url
      t.datetime :last_login_at
      t.datetime :last_request_at
      t.datetime :current_login_at
      t.string :last_login_ip
      t.string :current_login_ip
      t.timestamps
    end

    add_index :users, :login
    add_index :users, :wind_login
    add_index :users, :persistence_token
    add_index :users, :last_request_at

  end
  
  def self.down
    drop_table :users
  end
end
