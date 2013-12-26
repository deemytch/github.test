require 'haml'
require 'sass/plugin/rack'
require 'sinatra/base'
require 'json'
require 'thin'
require 'net/http'
require 'uri'

class Main < Sinatra::Base
	enable :logging, :dump_errors, :sessions
	set :port, 3001
	set :bind, 'localhost'

	get '/' do
		haml :search
	end

  get '/s' do
    p params
    params[:p].gsub(/^https:\/\/github.com\/|^\//,'') =~ /^([^\/]+)\/([^\/]+)/
    @user = $1
    @proj = $2
    uri = URI "https://api.github.com/repos/#{@user}/#{@proj}"
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      @repo = JSON.parse( http.request(Net::HTTP::Get.new uri).body )
    end
    p @repo
    haml :mined
  end
  
	run! if app_file == $0
end
