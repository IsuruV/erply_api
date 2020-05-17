class AddColumnErplyCode < ActiveRecord::Migration[5.0]
  def change
    add_column :mini_bars, :erply_id, :string
  end
end
