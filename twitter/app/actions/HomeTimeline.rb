require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

class HomeTimeline < Cramp::Action
  use_fiber_pool :size => 1
	def start
    DB.new.home_timeline(params[:screen_name]) do |tweets|
      if tweets.nil?
        render "Czego?\n"
        finish
      else
        render '['
        result = tweets.map do |row|
          %{{"created_at":"#{row['created_at']}","text":"#{row['text']}","id":#{row['id']},"user":{"id":#{row['user_id']},"name":"#{row['name']}","screen_name":"#{row['screen_name']}"}}}
        end.join(",\n")
        render result
        render ']'
        finish
      end
    end
	end
end
