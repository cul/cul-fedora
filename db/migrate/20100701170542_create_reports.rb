class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.string :name, :null => false
      t.string :category, :null => false
      t.datetime :generated_on
      t.integer :user_id
      t.text :options
      t.text :data

      t.timestamps
    end

    add_index :reports, :category

  end

  def self.down
    drop_table :reports
  end
end
