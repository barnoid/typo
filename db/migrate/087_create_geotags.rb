class CreateGeotags < ActiveRecord::Migration
  def self.up
    create_table :geotags do |t|
      t.integer :article_id
      t.float :lat, :limit => 25
      t.float :lon, :limit => 25
      t.integer :accuracy
      t.string :name
    end
  end

  def self.down
    drop_table :geotags
  end
end
