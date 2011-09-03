class HomeTimeline < Cramp::Action
	def start
		render "HomeTimeline"
    DB.new.test
		finish
	end
end
