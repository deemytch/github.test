require 'haml'
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
    unless params['message'].nil?
      @flash_msg = params['message']
    end
		haml :search
	end

  get '/s' do
    if params.nil? || params[:p].nil? || params[:p].empty?
      redirect '/'
    end
    params[:p].gsub(/^https:\/\/github.com\/|^\//,'') =~ /^([^\/]+)(\/([^\/]+))?/
    @org = $1
    @proj = $2
    @base = 'https://api.github.com'
    uri = {}
    uri[:orgs] = URI "#{@base}/orgs/#{@org}"
    uri[:repo] = URI "#{@base}/repos/#{@org}/#{@proj}"
    uri[:people] = URI "#{@base}/repos/#{@org}/#{@proj}/stats/contributors"
    uri[:code_frequency] = URI "#{@base}/repos/#{@org}/#{@proj}/stats/code_frequency"
    hdr = { 'Accept' => 'application/vnd.github.v3' }
#    @repo = {}
#    @repo['description'] = 'test descr'
#    @people = []
#    @code_frik = []
    
#TODO: error handling needed
#TODO: caching 202 -> 200 waiting also
    Net::HTTP.start(uri[:orgs].host, uri[:orgs].port, :use_ssl => true) do |http|
      # checking if that is an organization
      resp = http.request(Net::HTTP::Get.new(uri[:orgs], hdr ))
      p resp.code
      if resp.code == '404'
        @flash_msg = "'#{@org}' is not an organization"
        redirect "/?message=#{@flash_msg}"
      else
        @org_data = JSON.parse( resp.body )
        # repo common data
        # @repo = JSON.parse( http.request(Net::HTTP::Get.new(uri[:repo], hdr )).body )
        # contributors
        # @people = JSON.parse( http.request(Net::HTTP::Get.new(uri[:people], hdr )).body )
        # code frequency - additions and deletions per week
        # @code_frik = JSON.parse( http.request(Net::HTTP::Get.new(uri[:code_frequency], hdr )).body )
      end
    end

    haml :mined
  end
  
	run! if app_file == $0
end
