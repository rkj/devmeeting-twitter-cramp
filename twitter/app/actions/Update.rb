require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

class Update < Cramp::Action
	def start
		render "Hello World!\n"
		p params
		finish
	end
end

