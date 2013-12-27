require 'haml'
require 'sinatra/base'
require 'json'
require 'thin'
require 'net/http'
require 'uri'
require 'time'

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
    @today = Time.now
    uri = {}
    uri[:orgs] = URI "#{@base}/orgs/#{@org}"
    uri[:people] = URI "#{@base}/orgs/#{@org}/members"
    uri[:repo] = URI "#{@base}/repos/#{@org}/#{@proj}"
    uri[:code_frequency] = URI "#{@base}/repos/#{@org}/#{@proj}/stats/code_frequency"
    hdr = { 'Accept' => 'application/vnd.github.v3' }
#    @org = {}
#    @people = []
    
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
        #get people
        @people = JSON.parse( http.request(Net::HTTP::Get.new(uri[:people], hdr )).body )
        #get people activity for today
        # and here`s a problem: github blocks too frequent non-authed requests
        @people.each do |man|
          man[:events] = JSON.parse( http.request(Net::HTTP::Get.new("https://api.github.com/users/#{man['name']}/events", hdr)).body ).select do |e|
            t = Time.parse(e['created_at'])
            t.year == @today.year && t.month == @today.month && t.day == @today.day
          end
        end
        #sort by that activity
        @people.sort!{|a,b| a[:events].size <=> b[:events].size }
        @active = []
        count = 0 # showin only the first 10 brave programmers
        @people.each do |man|
          break if(man[:events].size == 0)||(count > 9)
          @active << man
          count+=1
        end
        # repo common data
        # @repo = JSON.parse( http.request(Net::HTTP::Get.new(uri[:repo], hdr )).body )
        # code frequency - additions and deletions per week
        # @code_frik = JSON.parse( http.request(Net::HTTP::Get.new(uri[:code_frequency], hdr )).body )
      end
    end
    # @people = { :login, :avatar_url, :events => { event } }
    haml :mined
  end
  
	run! if app_file == $0
end
