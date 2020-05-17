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
        #if code!="" && !item['images'] && Item.where(code:code).length == 0
		db_item = Item.where(code: code).first
		if(db_item && db_item.processed == false)
			code = db_item.name
		end
        if (!item['images'] && (db_item == nil) || (!item['images'] && db_item.processed == false))
          img = GoogleImage.image_bytes(code, item['name'])
          if !!img
            resp = self.api.sendRequest_mod('add_pics', {'picture' => 'data:image/png;base64,'+img, 'fileName': item['name'].delete(' ') + '.jpg', 'productID' => item['productID']})
			resp_json = JSON.parse(resp)
			stat = resp_json['status']
			if stat != "OK"
				if db_item == nil
					Item.new(code:code, processed: false, name: item['name']).save
				end
			end
			print resp+"\n"+"item: #{item['name']}"
		else
			if db_item == nil
				Item.new(code:code, processed: true, name: item['name']).save
			else
				db_item.update(processed:true)
			end


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
    def set_item_image_mod(item)
      base = item.img_base || " "
      resp = self.api.sendRequest_mod('add_pics', {'picture' => 'data:image/png;base64,'+base, 'fileName': item.name.squish.gsub(" ", "")+'.jpg', 'productID' => item.erply_id})
    end

    def delete_image(item_id)
      self.api.sendRequest("deleteProductPicture", {"productID" =>item_id})
    end

    def set_item_description(item)
      description = "<div>#{item.description}</div>"
      country = !!item.country && item.country != "" ? "<b>Country: #{item.country}</b>" : nil
      region = !!item.region && item.region != "" ? "<b>Region: #{item.region}</b>" : nil
      final_description = "#{country}\n #{region}\n #{description}"
      self.api.sendRequest("saveProduct", {"productID" =>item.erply_id, "description" => final_description,
          "descriptionEST" => final_description, "longdesc" => final_description, "longdescEST" => final_description})
    end

    def self.get_updated_inventory(instance)
      instance.get_product_ids_quantities
      instance.get_detailed_info
      instance.merge_quantities
    end

    def get_updated_inventory
      self.get_product_ids_quantities
      self.get_detailed_info
      self.merge_quantities
    end

    def update_newly_added_products
      self.get_updated_inventory
      products = self.items
      new_products = []
      miniBar = MiniBar.new
      products.each do |prod|
        existingProduct = MiniBar.all.where(erply_id: prod['productID']).first
        if existingProduct == nil
          new_products.push(prod)
        end
      end
      new_products.each do |prod|
         miniBar.save_product(prod['name'], prod['productID'])
      end
      self.save_to_erply(new_products)
    end

    def retrive_miniBar_info
      self.get_updated_inventory
      products = self.items[1000..1200]
      miniBar = MiniBar.new
      products.each do |prod|
        begin
          miniBar.save_product(prod['name'], prod['productID'])
        rescue
          File.write("/Users/isuruvidanapathirana/Desktop/erply/erply_api/error/miniBar_error.txt", "#{prod['name']}, \n #{miniBar.get_formatted_product_name(prod['name'])},\n", mode: 'a')
          print "\n Mini Bar Error with: #{prod['name']}]\n #{miniBar.get_formatted_product_name(prod['name'])} \n"
        end
      end
    end

    def save_to_erply(items)
      items.each do |item|
        minibar_item = MiniBar.all.where(erply_id: item['productID']).first
        if(minibar_item != nil)
          desc_response = JSON.parse(self.set_item_description(minibar_item))
          img_response = JSON.parse(self.set_item_image_mod(minibar_item))
          desc_stat = desc_response['status']['responseStatus']
          img_stat = img_response['status']
          if(desc_stat == "ok")
             minibar_item.update(desc_proc: true)
          end
          if(img_stat == "OK")
            minibar_item.update(img_proc: true)
          end
          if(img_stat == "FAIL")
            print "failed uploading image: #{minibar_item.name}"
            #minibar_item.update(img_proc: false)
            minibar_item.destroy
          end
        end
      end
    end

    def set_item_info_from_minibar
      products = MiniBar.all.where(desc_proc: nil, img_proc: nil)
      #products = MiniBar.all
      # self.set_items
      #i.items.select{ |i| i['productID'] == 586 }.count
      products.each do |minibar_item|
        desc_response = JSON.parse(self.set_item_description(minibar_item))
        img_response = JSON.parse(self.set_item_image_mod(minibar_item))
        desc_stat = desc_response['status']['responseStatus']
        img_stat = img_response['status']
        if(desc_stat == "ok")
           minibar_item.update(desc_proc: true)
        end
        if(img_stat == "OK")
          minibar_item.update(img_proc: true)
        end
        if(img_stat == "FAIL")
          print "failed uploading image: #{minibar_item.name}"
          minibar_item.update(img_proc: false)
        end
      end
    end

    def total_failed_uploads
      total = MiniBar.all.where(processed:false).count
      total += MiniBar.all.where(img_proc:false).count
    end

    def delete_all_images
      products = MiniBar.all.where(img_proc:true)
      products.each do |prod|
        self.delete_image(prod.erply_id)
      end
    end
    def reset_images_from_minibar
      self.delete_all_images
      products = MiniBar.all.where(img_proc:true)
      products.each do |prod|
        self.set_item_image_mod(prod)
      end
    end

    # def singl_item(item)
    #   self.delete_image(item.erply_id)
    #   self.set_item
    # end

end
