class AddColumnsToMinibar < ActiveRecord::Migration[5.0]
  def change
    add_column :mini_bars, :type, :string
    add_column :mini_bars, :category, :string
    add_column :mini_bars, :brand_name, :string
    add_column :mini_bars, :region, :string
    add_column :mini_bars, :country, :string
    add_column :mini_bars, :varietal, :string
    add_column :mini_bars, :thumb_url, :string
  end
end
