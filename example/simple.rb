
require 'sinatra/base'
class Simple < Sinatra::Base
  get '/' do
    'Hello!'
  end
end