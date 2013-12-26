require 'haml'
require 'sass/plugin/rack'
require 'sinatra/base'
require 'json'
require 'thin'

class Main < Sinatra::Base
	enable :logging, :dump_errors, :sessions
	set :port, 3001
	set :bind, 'localhost'

	get '/' do
		haml :index
	end

  get '/s' do
    haml :search
  end
  
	run! if app_file == $0
end
