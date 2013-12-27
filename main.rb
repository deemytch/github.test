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
    @today = Time.now.strftime("%a, %d %b %Y 00:00:00 GMT")
    uri = {}
    uri[:orgs] = URI "#{@base}/orgs/#{@org}"
    uri[:people] = URI "#{@base}/orgs/#{@org}/members"
    uri[:repo] = URI "#{@base}/repos/#{@org}/#{@proj}"
    uri[:code_frequency] = URI "#{@base}/repos/#{@org}/#{@proj}/stats/code_frequency"
    hdr = { 'Accept' => 'application/vnd.github.v3' }
    hdrtime = { 'Accept' => 'application/vnd.github.v3', 'If-Modified-Since' => @today }
#    @org = {}
#    @people = []
    
#TODO: error handling needed
#TODO: caching 202 -> 200 waiting also
    Net::HTTP.start(uri[:orgs].host, uri[:orgs].port, :use_ssl => true) do |http|
      # checking if that is an organization
      rq = Net::HTTP::Get.new(uri[:orgs], hdr )
#          rq.basic_auth 'user', 'pass'
      
      resp = http.request(rq)
      p resp.code
      if resp.code == '404'
        @flash_msg = "'#{@org}' is not an organization"
        redirect "/?message=#{@flash_msg}"
      elsif resp.code == '403' # rate limit exceeded
        @flash_msg = "Rate limit exceeded. Try again in one hour."
        redirect "/?message=#{@flash_msg}"
      else
        stream do |out|
          out << "<p id='streamed_tmp'>Checking activity "
          @org_data = JSON.parse( resp.body )
          #get people
          rq = Net::HTTP::Get.new(uri[:people], hdr )
#          rq.basic_auth 'user', 'pass'
          
          @people = JSON.parse( http.request(rq).body )
          out << "of the #{@people.size} members: "
#          puts "of the #{@people.size} members: "
          #get people activity for today
          # and here`s a problem: github blocks more than 60 non-authorized requests per hour,
          # so I use If-Modified-Since and hoping to the best
          @active = []
          @people.each do |man|
            out << "#{man['login']} "
#            puts man['login']

            rq = Net::HTTP::Get.new("https://api.github.com/users/#{man['login']}/events", hdrtime)
#          rq.basic_auth 'user', 'pass'
            
            req = http.request(rq)
            if req.code == '200'
              @active << { :login => man['login'], :ava => man['avatar_url'], :url => man['html_url'], :events => JSON.parse( req.body ) }
              out << "* "
            end
          end
#          puts "Total #{@active.size} active members"
          p @active
          #sort by that activity
          @active.sort!{|a,b| a[:events].size <=> b[:events].size }
          @active.reverse!
          out << '</p>'
          out << haml(:mined)
        end
      end
    end
  end
  
	run! if app_file == $0
end
