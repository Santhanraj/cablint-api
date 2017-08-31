require 'sinatra/base'
require 'json'

class MyApp < Sinatra::Base
  before do
      content_type :json
  end


  post "/" do
      payload = JSON.parse(request.body.read, :symbolize_keys => true)
      { serial_no: payload[:serial_no], success: "1"}.to_json
  end
end
