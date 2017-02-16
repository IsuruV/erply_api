require 'json'
require 'net/http'
require 'uri'
require 'OpenSSL'

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
