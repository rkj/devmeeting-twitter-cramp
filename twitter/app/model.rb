require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

class DB
  SHARD_COUNT = 4
  #DBCONN = {:host => "10.1.1.10", :username => "devcamp", :password => "devcamp"}
  DBCONN = {:host => "localhost", :username => "root"}
  @@db = Proc.new do
    (1..SHARD_COUNT).map do |i|
      conn = Mysql2::EM::Client.new(DBCONN.merge(:database => "twitter#{i}"))
			[conn, i]
    end
  end

  def db_for_user(name)
    counter = SHARD_COUNT
    ret = []
    acquired = @@db.call
    #puts "Acquired #{fiber.inspect} on dbs: #{acquired.inspect}"
    acquired.each do |db, dbno|
      #puts "Querying: #{db.inspect}"
      q = db.aquery("SELECT id FROM users WHERE screen_name = '#{name}'")
      q.errback do |r|
        #puts "User get error: #{r}"
        counter -= 1
      end
      q.callback do |r|
        #puts "Result from #{db.inspect}"
        counter -= 1
        if r.size > 0
          r.each do |userRow|
            ret = [db, userRow['id']]
          end
        end
        if counter == 0
          yield ret[0], ret[1], acquired
        end
      end
    end
  end

  def home_timeline(name, &blk)
    db_for_user(name) do |db, user_id, conns|
      conns.each { |c| c.close } 
      if db.nil? 
        yield nil
      else
        query_all("SELECT s.id, s.text, s.created_at, u.id AS user_id, u.name, u.screen_name FROM statuses s, followers f, users u WHERE u.id = s.user_id AND s.user_id = f.user_id AND f.follower_id = #{user_id} LIMIT 20", &blk)
      end
    end
  end

  def query_all(query)
    counter = SHARD_COUNT
    result = []
    acquired = @@db.call
    check_finish = Proc.new do 
      #puts "Checking #{counter}"
      counter -= 1
      if counter == 0
        acquired.each { |c| c.close } 
        puts "SENDING RESULTS #{result.size}"
        yield result
      end
    end
    acquired.each do |db, dbno|
      #puts "Querying: #{db.inspect}"
      begin
        q = db.aquery(query)
      rescue => e
        p e
        next
      end
      q.errback { |r| puts "ERROR in #{query} on #{db.inspect}:\n#{r}"; check_finish.call }
      q.callback do |r|
        puts "Partial results: #{r.size} for #{dbno}"
        result += r.each.to_a
        check_finish.call
        #puts "Bye"
      end
    end
  end

end
