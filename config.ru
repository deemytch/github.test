#\ -p3001 -w -s thin -o 0.0.0.0
require "sinatra"

require File.expand_path '../main.rb', __FILE__

run Main
