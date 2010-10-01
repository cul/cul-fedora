class CreateContentBlocks < ActiveRecord::Migration
  def self.up
    create_table :content_blocks do |t|
      t.string :title, :unique => true, :null => false
      t.integer :user_id, :null => false
      t.text :data

      t.timestamps
    end

    add_index :content_blocks, :title
  end

  def self.down
    drop_table :content_blocks
  end
end
