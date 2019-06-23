class Inventory
    attr_accessor :api, :items, :ids_quantities
    def initialize(user_name, password)
        self.api = Erply.new
        self.api.clientCode = "295038"
        self.api.username = user_name
        self.api.password = password
        self.api.url = "https://"+self.api.clientCode+".erply.com/api/"
    end
    
    def set_items
      self.get_product_ids_quantities
      self.get_detailed_info
    end

    def formatted_items
      arr = []
      self.items.each do |item|
        arr << {'productID': item['productID'], 'name': item['name'], 'price': item['price'],
                'in_stock': item['in_stock'], 'code': item['code'], 'groupID': item['groupID'],
              'active': item['active'], 'displayedInWebshop': item['displayedInWebshop'], 'description': item['description'],
              'longdesc': item['longdesc'], 'added': item['added'], 'addedByUsername': item['addedByUsername'], 'lastModified': item['lastModified'],
            'lastModifiedByUsername': item['lastModifiedByUsername'], 'seriesName': item['seriesName'], 'groupName': item['groupName'],
            'categoryID': item['categoryID'], 'categoryName': item['categoryName'], 'status': item['status'], 'nonStockProduct': item['nonStockProduct'],
            'images': item['images'], 'type': item['type']}
      end
      arr
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
    
   def add_pics
      self.set_items
    
      self.items.each do |item|
        code = item['code2']
        should_search = false
        if item['code2'] == ""
          code = item['code']
          should_search = true
        end
        # if item['cod2'] == '856184006112' || item['code'] == '856184006112'
        #   binding.pry
        # end
        if should_search && code!="" && !item['images'] && Item.where(code:code).length == 0
        #if item['code2']!="" && !!item['images'] && item['images'].length == 0
      
          img = GoogleImage.image_bytes(code)
          if !!img
            resp = self.api.sendRequest_mod('add_pics', {'picture' => 'data:image/png;base64,'+img, 'fileName': item['name'].delete(' ') + '.jpg', 'productID' => item['productID']})
            print resp+"\n"+"item: #{item['name']}"
          end
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
    
    def get_products_with_no_images
      self.items.map{|item| item if !item["images"] }
    end
    
    def set_item_image(image, item_id)
      self.api.sendRequest("saveProductPicture", {"productID" =>item_id, "picture" => image})
    end

    def self.get_updated_inventory(instance)
      instance.get_product_ids_quantities
      instance.get_detailed_info
      instance.merge_quantities
    end

end
