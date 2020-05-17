class CreateMiniBars < ActiveRecord::Migration[5.0]
  def change
    create_table :mini_bars, :primary_key => :code do |t|
      t.string :name
      t.string :code
      t.string :image_url
      t.string :description
      t.boolean :processed
      t.string :error
      t.timestamps
    end
  end
end
