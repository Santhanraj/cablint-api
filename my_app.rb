require 'sinatra/base'
require 'json'
require 'openssl'

class MyApp < Sinatra::Base
  before do
      	content_type :json
  end


  post "/" do
      	payload = JSON.parse(request.body.read, :symbolize_names => true)
	raw = payload[:pem]
	sub_CN =""
	pem = OpenSSL::X509::Certificate.new raw	
	pem.subject.to_a.each do |attri|
        	sub_CN = attri[1].to_s if attri[0] == "CN"
    	end
	File.open("cert.cer", "wb") { |f| f.print pem }
	message = %x[ruby ../certlint/bin/cablint test.cer]	
      {subject: sub_CN, message: message, success: "1" }.to_json
  end
end
