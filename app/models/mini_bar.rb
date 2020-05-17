require 'open-uri'
require 'base64'

class MiniBar < ApplicationRecord
  BEARER_TOKEN = "bearer a1aa77333fb63ba654cd120d17beaf1027b2414aa9e47e7d97d1a273ac7560de"
  END_POINT = "https://minibardelivery.com/api/v2/supplier/9,23,27,95,110,145,164,250,296,378,382,386,
  388,394,410,417,427,435,479,480,481,485,488,491,510,517,539,541,562,565,572,589,686,687,721,791,792
              /product_grouping"
  def get_product_info(product_name)
    url = URI.encode("#{END_POINT}/#{product_name}?shipping_state=NY".squish)
    item = open(url, "Authorization" => BEARER_TOKEN).read
    JSON.parse(item)
  end

  def get_formatted_product_name(product_name)
    bracket_free = product_name.gsub(/\s*\(.+\)$/, '')
    down_cased = bracket_free.downcase
    ml_free = down_cased
    l_free = ml_free
    yearfree = l_free.gsub(/\b\d{4}\b/,"")
    sevenfree = yearfree.gsub("750ml", "")
    onefree = sevenfree.gsub("1l", "")
    fivefree = onefree.gsub("50ml", "")
    twomlfree = fivefree.gsub("200ml", "")
    threemlfree = twomlfree.gsub("375ml", "")
    fivemlfree = threemlfree.gsub("500ml", "")
    littlefree = fivemlfree.gsub("187ml","")
    threelit = littlefree.gsub("3l","")
    bigFree = threelit.gsub("1.5l","")
    mediumFree = bigFree.gsub("1.75l","")
    hugefree = mediumFree.gsub("5l","")
    space_free = hugefree.gsub(/[^0-9A-Za-z]/, ' ').split.join(" ")
    space_free.squish.strip.gsub(" ", "-")
  end

  def save_product(product_name, erply_id)
    begin
      formatted_name = self.get_formatted_product_name(product_name)
      product = get_product_info(formatted_name)
      name = product['name']
      code = product['id']
      description = product['description']
      product_type = product['type']
      category = product['category']
      img_url = product['image_url']
      thumb_url = product['thumb_url']
      country_prop = product['properties'].detect {|f| f["name"] == "Country" }
      region_prop = product['properties'].detect {|f| f["name"] == "Country" }
      region = ''
      country = ''
      if country_prop
        country = country_prop['value']
      end
      if region_prop
        country = region_prop['value']
      end
      brand_name = product['brand']
      img_base = ''
      thumb_img_base = ''

      items = MiniBar.where(code: code, erply_id: erply_id)
      if items.length == 0 || item.first.processed == false || item.first.processed
        begin
          retries ||= 0
          img_base = GoogleImage.base_image(img_url)
          thumb_img_base = GoogleImage.base_image(thumb_url)
          puts "try ##{ retries }"
          raise " error fetching retrying again"
        rescue
          print 'Error Getting image bases'
          retry if (retries += 1) <= 3
        end
          MiniBar.create(name: name, code: code, description: description, product_type: product_type,
                        category: category, image_url: img_url, thumb_url: thumb_url, region: region,
                        country: country, img_base: img_base, thumb_img_base: thumb_img_base,
                        brand_name: brand_name, erply_id: erply_id)
      end
    rescue
      print "Error getting product from mini bar: #{product_name}"
      MiniBar.create(name: product_name, erply_id: erply_id, processed: false)
    end
  end

end
