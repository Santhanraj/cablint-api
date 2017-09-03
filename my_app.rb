lib = File.expand_path("../../certlint/lib", __FILE__)
ext = File.expand_path("../../certlint/ext", __FILE__)
$:.unshift(lib)
$:.unshift(ext)


require 'certlint'
require 'sinatra/base'
require 'json'
require 'openssl'
require 'certlint/version'
require 'certlint/certlint'
require 'certlint/cablint'
require 'certlint/pemlint'
require 'certlint/namelint'
require 'certlint/generalnames'

class MyApp < Sinatra::Base
  before do
      	content_type :json
  end


  post "/" do
      	payload = JSON.parse(request.body.read, :symbolize_names => true)
	raw = payload[:pem]
	sub_CN =""
	begin
		pem = OpenSSL::X509::Certificate.new raw	
		pem.subject.to_a.each do |attri|
        		sub_CN = attri[1].to_s if attri[0] == "CN"
    		end
        	m, der = CertLint::PEMLint.lint(raw, 'CERTIFICATE')
        	m += CertLint::CABLint.lint(der)
        	{subject: sub_CN, message: m, success: "1" }.to_json
	rescue StandardError=>e
		{subject: "", message: e, success: "0" }.to_json	
	end
  end
end
