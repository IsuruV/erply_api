require 'open-uri'
require 'base64'
class GoogleImage
	#KEY="AIzaSyASFdFKVXFb_2D5IGL-XtvFS8nZGb-_FFg"
   KEY="AIzaSyDC46QLShibs2Fu53xAi_EbbAgXeNeqEXE"
   CX="001125335750256783612:yug7zrcrhks"
   #CX="004072363454246664075:6xf4ka4zdbi"
   END_POINT="https://www.googleapis.com/customsearch/v1?key=#{KEY}&cx=#{CX}&searchType=image&imgType=photo"
#https://developers.google.com/custom-search/v1/cse/list?apix_params=%7B%22q%22%3A%22699412000243%22%2C%22imgType%22%3A%22photo%22%7D
  
    #get first of 10 items
    def self.get_image_link(search_item)
        item = open("#{END_POINT}&q=#{search_item}").read
        readItems = JSON.parse(item)['items']
		#binding.pry
        if(!!readItems)
            readItems[0]['link']
        else
            nil
        end
    end

    def self.image_bytes(search_item, name)
        image_link = self.get_image_link(search_item)
        if !!image_link
            begin
                self.base_image(image_link)
            rescue
                print "error getting base64 \n"
				begin
					self.base_image(name)
				rescue
					print "Error getting by name \n"
				end
              
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
