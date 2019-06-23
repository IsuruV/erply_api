require 'open-uri'
require 'base64'
class GoogleImage
   KEY=""
   CX=""
   END_POINT="https://www.googleapis.com/customsearch/v1?key=#{KEY}&cx=#{CX}&searchType=image"

  
    #get first of 10 items
    def self.get_image_link(search_item)
        item = open("#{END_POINT}&q=#{search_item}").read
        readItems = JSON.parse(item)['items']
        if(!!readItems)
            readItems[0]['link']
        else
            nil
        end
    end

    def self.image_bytes(search_item)
        image_link = self.get_image_link(search_item)
        if !!image_link
            begin
                self.base_image(image_link)
            rescue
                print "error getting base64 \n"
                nil
            end
        else
            nil
        end
    end
    
    def self.base_image(image_link)
        Base64.encode64(open(image_link).read)
    end
    
end 


# https://www.googleapis.com/customsearch/v1?#=AIzaSyDC46QLShibs2Fu53xAi_EbbAgXeNeqEXE&#=001125335750256783612:yug7zrcrhks&searchType=image&q=lectures
