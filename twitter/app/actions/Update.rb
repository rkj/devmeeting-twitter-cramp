require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

class Update < Cramp::Action
	def start
		name = params[:screen_name]
		status = params[:status]
		createdAt = Time.now.to_s

		DB.new.db_for_user(name) do |db, id, pool, fiber|
			db.aquery("INSERT INTO statuses (text, created_at, user_id) VALUES ('#{status}', '#{createdAt}', #{id}); SELECT LAST_INSERT_ID() AS x;")
			query.callback do |r|
				p r
				pool.release(fiber)
				finish
			end
			query.errback do |r| 
				p r
				finish
			end
		end

	end
end

