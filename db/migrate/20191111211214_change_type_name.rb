class ChangeTypeName < ActiveRecord::Migration[5.0]
  def change
    rename_column :mini_bars, :type, :product_type
  end
end
