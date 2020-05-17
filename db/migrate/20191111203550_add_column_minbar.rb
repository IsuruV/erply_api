class AddColumnMinbar < ActiveRecord::Migration[5.0]
  def change
      add_column :mini_bars, :thumb_img_base, :string
      add_column :mini_bars, :img_base, :string
  end
end
