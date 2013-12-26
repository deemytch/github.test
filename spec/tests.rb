ENV['RACK_ENV'] = 'test'
require 'rspec'
require 'rack/test'
require File.dirname(__FILE__) + '/../main.rb'

module RSpecMixin
  include Rack::Test::Methods
  def app() Main end
end
RSpec.configure { |c| c.include RSpecMixin }
def app()
  Main
end


describe 'GitHub API statistics' do
  it 'should load home page' do
    get '/'
    expect(last_response).to be_ok
#    expect(last_response.body).to eq('Go')
  end

  it 'sould find the project deemytch/github.test' do
    get '/s', params = { p: 'deemytch/github.test' }
    expect(last_response).to be_ok
  end
end
