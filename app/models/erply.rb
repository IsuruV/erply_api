require 'json'
require 'net/http'
require 'uri'
# require 'OpenSSL'

class MissingArgumentsException < Exception
end
class VerifyUserException < Exception
end


class Erply

	def initialize(url = nil, clientCode = nil, username = nil, password = nil, sslCACertPath = nil)
		@url = url
		@clientCode = clientCode
		@username = username
		@password = password
		@sslCACertPath = sslCACertPath
	end

	#Setters and getters

	def url
		return @url
	end

	def url=(url)
		@url = url
	end

	def clientCode
		return @clientCode
	end

	def clientCode=(clientCode)
		@clientCode = clientCode
	end

	def username
	return @username
	end

	def username=(username)
	@username = username
	end

	def password
	return @password
	end

	def password=(password)
	@password = password
	end

	def sslCACertPath
	return @sslCACertPath
	end

	def sslCACertPath=(ssl)
	@sslCACertPath=ssl
	end

	def sendRequest(request, parameters = Hash.new)
		if(!@url || !@clientCode || !@username || !@password)
		raise MissingArgumentsException.new("Missing parameters")
		end

		#add extra params
		parameters['request'] = request
		parameters['clientCode'] = @clientCode
		parameters['version'] = '1.0'
		parameters['username'] = @username
		parameters['password'] = @password
    # parameters['responseType'] = 'CSV'
			if(request != "verifyUser") then
				parameters['sessionKey'] = getSessionKey()
			end
		#create request
		uri = URI.parse(url)
		handle = Net::HTTP.new(uri.host,uri.port)

		#create errors on timeout
		handle.read_timeout = 45

		#set up host and cert verification
		handle.use_ssl = true
		handle.verify_mode = OpenSSL::SSL::VERIFY_NONE
		if(@sslCACertPath) then
			handle.ca_file = @sslCACertPath
			handle.verify_mode = OpenSSL::SSL::VERIFY_PEER
		end

		#set the payload and run
		request = Net::HTTP::Post.new(uri.request_uri)
		request.set_form_data(parameters)
		response = handle.request(request)
		return response.body
	end

		def sendRequest_mod(request, parameters = Hash.new)
		if(!@url || !@clientCode || !@username || !@password)
		raise MissingArgumentsException.new("Missing parameters")
		end

		#add extra params
		parameters['request'] = request
		parameters['clientCode'] = @clientCode
		parameters['version'] = '1.0'
		parameters['username'] = @username
		parameters['password'] = @password
    # parameters['responseType'] = 'CSV'
			if(request != "verifyUser") then
				parameters['sessionKey'] = ""
			end
		#create request
		uri = URI.parse("https://pl10.erply.com/service/cdnconnectplugin/NEW_S3_UI_FILES/Helpers/uploadPicture.php")
		handle = Net::HTTP.new(uri.host,uri.port)

		#create errors on timeout
		handle.read_timeout = 45

		#set up host and cert verification
		handle.use_ssl = true
		handle.verify_mode = OpenSSL::SSL::VERIFY_NONE
		if(@sslCACertPath) then
			handle.ca_file = @sslCACertPath
			handle.verify_mode = OpenSSL::SSL::VERIFY_PEER
		end

		#set the payload and run
		response = Net::HTTP.post_form(uri, parameters)
		#request.set_form_data(parameters)
		#response = handle.request(request)
		#binding.pry
		return response.body
	end

	private
	def getSessionKey()
		#if no session key or expired, then obtain it
		if(!defined?(@session['EAPISessionKey'][@clientCode][@username]) ||
		!defined?(@session['EAPISessionKeyExpires'][@clientCode][@username]) ||
		@session['EAPISessionKeyExpires'][@clientCode][@username] < Time.now.to_i)
			#make request
			result = sendRequest("verifyUser", {"username" => @username, "password" => @password})
			result = JSON.parse(result)
				#Check for errors
				if(!defined?(result['records'][0]['sessionKey']))
					raise VerifyUserException.new("Verify user failure")
				end
			@session = {'EAPISessionKey' =>
											{
												@clientCode => {
													@username => result['records'][0]['sessionKey']
												}
											},
						'EAPISessionKeyExpires' =>
											{
												@clientCode => {
													@username => Time.now.to_i + result['records'][0]['sessionLength'] - 30
												}
											}
						}
		end
		return @session['EAPISessionKey'][@clientCode][@username]
	end
end


#https://minibardelivery.com/api/v2/supplier/687,382,27,296,565,572,686,792,250,145,386,517,480,394,479,378,110,562,417,23,539,427,721,510,410,541,435,481,388,589,791,491,9,488,485,164,95/related?count=8&product_grouping_id=bulleit-bourbon&product_grouping_similarity_type=content&shipping_state=NY
#https://minibardelivery.com/store/product/bulleit-bourbon
#https://minibardelivery.com/store/product/agustinos-cabernet-sauvignon?q=agustinos%20cabernet%20sau&sc=product
#https://minibardelivery.com/api/v2/supplier/9,23,27,95,110,145,164,250,296,378,382,386,388,394,410,417,427,435,479,480,481,485,488,491,510,517,539,541,562,565,572,589,686,687,721,791,792/product_grouping/agustinos-cabernet-sauvignon?shipping_state=NY
