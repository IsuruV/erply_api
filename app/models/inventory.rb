class Inventory
    attr_accessor :api, :items, :ids_quantities
    def initialize
        self.api = Erply.new
        self.api.clientCode = "295038"
        self.api.username = "drizly"
        self.api.password = "drizly123"
        self.api.url = "https://"+self.api.clientCode+".erply.com/api/"
    end

    def get_product_ids_quantities
      self.ids_quantities = []
      products = self.api.sendRequest("getProductStock", {"warehouseID" => 1})
      products_formatted = JSON.parse(products)['records']
      products_formatted.each do |product|
        if product['amountInStock'].to_i > 0
          self.ids_quantities << product
        end
      end
    end

    def get_detailed_info
      ## api only gets 1,000 items max at a time
      self.items = []

      first_thousand_items = self.ids_quantities[0..1000].map{|product| product['productID']}.join(",")
      rest_items = self.ids_quantities[1001..self.ids_quantities.length].map{|product| product['productID']}.join(",")

      first_result = JSON.parse(api.sendRequest("getProducts", {"warehouseID" => 1, "getParameters" => 1, "type"=> "PRODUCT", "recordsOnPage" => 1000, "status" => "ACTIVE", "active"=> 1, "productIDs" => first_thousand_items}))
      second_result = JSON.parse(api.sendRequest("getProducts", {"warehouseID" => 1, "getParameters" => 1, "type"=> "PRODUCT", "recordsOnPage" => 1000, "status" => "ACTIVE", "active"=> 1, "productIDs" => rest_items}))

      first_result['records'].each{|product| self.items << product}
      second_result['records'].each{|product| self.items << product}
    end

    def merge_quantities
      self.items.map do |item|
        self.ids_quantities.each do |quantity|
          if item['productID'].to_i == quantity['productID'].to_i
            item['in_stock'] = quantity["amountInStock"]
          end
        end
      end
    end

    def self.get_updated_inventory(instance)
      instance.get_product_ids_quantities
      instance.get_detailed_info
      instance.merge_quantities
    end

end
