require 'sinatra'

class App < Sinatra::Base
  get('/success') do
    status 200
  end

  post('/404') do
    status 404
  end
  
  post('/503')  do
    status 503
  end
end

run App