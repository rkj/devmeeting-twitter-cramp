require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

class HomeTimeline
	def start
		render "HomeTimeline"
		name = params[:screen_name]
		db = Mysql2::EM::Client.new(:host => "10.1.1.10", :username => "devcamp", :password => "devcamp", :database => "twitter1")
		finish
	end
end
