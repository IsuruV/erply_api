class AddColumnMinibar < ActiveRecord::Migration[5.0]
  def change
    add_column :mini_bars, :img_proc, :boolean
    add_column :mini_bars, :desc_proc, :boolean
  end
end
