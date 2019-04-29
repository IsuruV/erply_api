require 'open-uri'
require 'base64'
class GoogleImage
    KEY =""
    CX = ""
    END_POINT="https://www.googleapis.com/customsearch/v1?key=#{KEY}&cx=#{CX}&searchType=image"
  
    #get first of 10 items
    def self.get_image_link(search_item)
        JSON.parse(open("#{END_POINT}&q=#{search_item}").read)['items'][0]['link']
    end

    def self.image_bytes(search_item)
        image_link = self.get_image_link(search_item)
        Base64.encode64(open(image_link).read)
    end
    
end 


