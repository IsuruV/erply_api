class InventoryController < ApplicationController

    def index
      @updated_inventory = Inventory.new
      Inventory.get_updated_inventory(@updated_inventory)
      respond_to do |format|
        format.csv { render csv: @updated_inventory.items }
        format.json { render json: @updated_inventory.items }
      end
    end

end
