require 'google_image'
class ImageParser
    attr_accessor :items, :inventory, :error_items, :success_items
    
    def initialize(username, password)
        self.inventory = Inventory.new(username, password)
        self.inventory.get_product_ids_quantities
        self.inventory.get_detailed_info
        self.error_items = []
        self.success_items = []
    end
    
    def set_items_with_no_images
        self.items = self.inventory.get_products_with_no_images.compact
    end
    
    def add_missing_images
        self.set_items_with_no_images
        self.items.each do |item|
            begin
                image = GoogleImage.image_bytes(item['code2'])
                inventory.set_item_image(image, item['productID'])
                self.success_items.push({:'code' => item['code2'], :'name' => item['name']})
                print "SUCCESS: item_code:#{item['code2']}, item_name: #{item['name']}"
            rescue
                self.error_items.push({:'code' => item['code2'], :'name' => item['name']})
                 print "ERROR: item_code:#{item['code2']}, item_name: #{item['name']}"
            ensure 
             print "\n"
            end
        end    
    end
end

# code2