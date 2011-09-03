require 'sinatra'
require 'mysql2'

class DB
  SHARD_COUNT = 4
  MAX_CONN = 150
  DBCONN = {:host => "10.1.1.10", :username => "devcamp", :password => "devcamp"}
  @@db = Proc.new do
    (1..SHARD_COUNT).map do |i|
      Mysql2::Client.new(DBCONN.merge(:database => "twitter#{i}"))
    end
  end

	def db_for_user(name)
		acquired = @@db.call
		begin
			acquired.each do |db|
				r = db.query("SELECT id FROM users WHERE screen_name = '#{name}'")
				if r.size > 0
					r.each do |userRow|
						return [db, userRow['id']]
					end
				end
			end
		ensure
			acquired.each { |conn| conn.close }
		end
	end

  def home_timeline(name, &blk)
    (db, id) = db_for_user(name) do
      if db.nil? 
        yield nil
      else
        query_all("SELECT s.id, s.text, s.created_at, u.id AS user_id, u.name, u.screen_name FROM statuses s, followers f, users u WHERE u.id = s.user_id AND s.user_id = f.user_id AND f.follower_id = #{user_id} LIMIT 20", &blk)
      end
    end
  end

  def query_all(query)
    result = []
		acquired = @@db.call
		acquired.each do |db|
			begin
				r = db.query(query)
				result += r
			rescue => e
				p e
				next
			end
		end
		result
	end

end

get '/statuses/home_timeline' do
	DB.new.home_timeline(params[:screen_name]) do |tweets|
		if tweets.nil?
			render "Czego?\n"
			return finish
		end
		render '['
		result = tweets.map do |row|
			%{{"created_at":"#{row['created_at']}","text":"#{row['text']}","id":#{row['id']},"user":{"id":#{row['user_id']},"name":"#{row['name']}","screen_name":"#{row['screen_name']}"}}}
		end.join(",\n")
		render result
		render ']'
		finish
	end
end
