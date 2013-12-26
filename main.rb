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
    @base = 'https://api.github.com'
    uri = {}
    uri[:repo] = URI "#{@base}/repos/#{@user}/#{@proj}"
    uri[:people] = URI "#{@base}/repos/#{@user}/#{@proj}/stats/contributors"
    uri[:code_frequency] = URI "#{@base}/repos/#{@user}/#{@proj}/stats/code_frequency"
    
#TODO: error handling needed
#TODO: caching 202 -> 200 waiting also
    Net::HTTP.start(uri[:repo].host, uri[:repo].port, :use_ssl => true) do |http|
      # repo common data
      @repo = JSON.parse( http.request(Net::HTTP::Get.new uri[:repo]).body )
      # contributors
      @people = JSON.parse( http.request(Net::HTTP::Get.new uri[:people]).body )
      # code frequency - additions and deletions per week
      @code_frik = JSON.parse( http.request(Net::HTTP::Get.new uri[:code_frequency]).body )
    end
    haml :mined
  end
  
	run! if app_file == $0
end
