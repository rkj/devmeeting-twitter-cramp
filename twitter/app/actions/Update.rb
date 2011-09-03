require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

class Update < Cramp::Action
	def start
		db = Mysql2::EM::Client.new(:host => "10.1.1.10", :username => "devcamp", :password => "devcamp", :database => "twitter1")
		render "Hello World!\n"
		finish
	end
end

