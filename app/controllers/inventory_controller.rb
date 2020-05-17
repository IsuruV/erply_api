
class InventoryController < ApplicationController

    def index
      @updated_inventory = Inventory.new(params[:user_name], params[:password])
      Inventory.get_updated_inventory(@updated_inventory)
      # all_keys_as_array = %w{productID name code code2 code3 supplierCode groupID price active displayedInWebshop seriesID supplierID unitID vatrateID hasQuickSelectButton isGiftCard manufacturerName priorityGroupID countryOfOriginID brandID length width height netWeight grossWeight volume description longdesc descriptionENG longdescENG descriptionRUS longdescRUS descriptionFIN longdescFIN containerID cost added addedByUsername lastModified lastModifiedByUsername vatrate priceWithVat unitName brandName seriesName groupName supplierName categoryID categoryName status attributes taxFree backbarCharges isRegularGiftCard nonStockProduct rewardPointsNotAllowed deliveryTime longAttributes images type locationInWarehouse in_stock  }
      all_keys_as_array = %w{productID name price in_stock code groupID active displayedInWebshop description longdesc added addedByUsername lastModified lastModifiedByUsername seriesName groupName categoryID categoryName status nonStockProduct images type }
      h = CSV::Row.new(all_keys_as_array,[],true)
      t = CSV::Table.new([h])

      require 'csv'

      @updated_inventory.formatted_items.each do |item|
        r = CSV::Row.new([],[],false)
        all_keys_as_array.each do |key|
          r << item[key]
        end
        t << r
      end

      respond_to do |format|
        format.csv { render csv: t.to_csv }
        format.json { render json: @updated_inventory.formatted_items }
      end
    end

end
