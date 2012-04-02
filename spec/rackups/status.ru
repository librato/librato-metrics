require 'sinatra'

class App < Sinatra::Base
  get('/v1/success') do
    status 200
  end

  post('/v1/forbidden') do
    status 403
  end

  get('/v1/not_found') do
    status 404
  end
  
  post('/v1/service_unavailable')  do
    status 503
  end
end

run App