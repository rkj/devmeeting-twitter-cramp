require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

module Twit
  class ConnectionPool
    def initialize(opts, &block)
      @reserved  = {}   # map of in-progress connections
      @available = []   # pool of free connections
      @pending   = []   # pending reservations (FIFO)

      opts[:size].times do
        @available.push(block.call) if block_given?
      end
    end

    # Choose first available connection and pass it to the supplied
    # block. This will block indefinitely until there is an available
    # connection to service the request.
    def execute(async)
      f = Fiber.current

      begin
        conn = acquire(f)
        yield conn, f
      ensure
        release(f) if not async
      end
    end

    # Acquire a lock on a connection and assign it to executing fiber
    # - if connection is available, pass it back to the calling block
    # - if pool is full, yield the current fiber until connection is available
    def acquire(fiber)
      #puts "ACQUIRE #{fiber.inspect}"

      if conn = @available.pop
        @reserved[fiber.object_id] = conn
        conn
      else
        Fiber.yield @pending.push fiber
        acquire(fiber)
      end
    end

    # Release connection assigned to the supplied fiber and
    # resume any other pending connections (which will
    # immediately try to run acquire on the pool)
    def release(fiber)
      #puts "Releaseing fiber: #{fiber.inspect}"
      @available.push(@reserved.delete(fiber.object_id))

      if pending = @pending.shift
        pending.resume
      end
    end

    # Allow the pool to behave as the underlying connection
    #
    # If the requesting method begins with "a" prefix, then
    # hijack the callbacks and errbacks to fire a connection
    # pool release whenever the request is complete. Otherwise
    # yield the connection within execute method and release
    # once it is complete (assumption: fiber will yield until
    # data is available, or request is complete)
    #
    def method_missing(method, *args, &blk)
      async = (method[0,1] == "a")

      execute(async) do |conn|
        df = conn.send(method, *args, &blk)

        if async
          fiber = Fiber.current
          df.callback { release(fiber) }
          df.errback { release(fiber) }
        end

        df
      end
    end
  end

end

class DB
  SHARD_COUNT = 4
  MAX_CONN = 8
  DBCONN = {:host => "10.1.1.10", :username => "devcamp", :password => "devcamp"}
  #DBCONN = {:host => "localhost", :username => "root"}
  @@db = Twit::ConnectionPool.new(size: MAX_CONN/SHARD_COUNT) do
    puts "PULA"
    (1..SHARD_COUNT).map do |i|
      Mysql2::EM::Client.new(DBCONN.merge(:database => "twitter#{i}"))
    end
  end

  def db_for_user(name)
    counter = SHARD_COUNT
    ret = []
    @@db.execute(true) do |acquired, fiber|
      acquired.each do |db|
        q = db.aquery("SELECT id FROM users WHERE screen_name = '#{name}'")
        q.errback do |r|
          puts "User get error: #{r}"
          counter -= 1
        end
        q.callback do |r|
          counter -= 1
          if r.size > 0
            r.each do |userRow|
              ret = [db, userRow['id']]
            end
          end
          if counter == 0
            yield ret[0], ret[1], @@db, fiber
          end
        end
      end
    end
  end

  def home_timeline(name, &blk)
    db_for_user(name) do |db, user_id, pool, fiber|
      pool.release(fiber)
      if db.nil? 
        yield nil
      else
        #query_all("SELECT s.id, s.text, s.created_at, u.id AS user_id, u.name, u.screen_name FROM statuses s, followers f, users u WHERE u.id = s.user_id AND s.user_id = f.user_id AND f.follower_id = #{user_id}", &blk)
        yield nil
      end
    end
  end

  def query_all(query)
    counter = SHARD_COUNT
    result = []
    @@db.execute(true) do |acquired, fiber|
      #puts "Acquired pool"
      check_finish = Proc.new do 
        #puts "Checking #{counter}"
        counter -= 1
        if counter == 0
          @@db.release(fiber)
          #puts "SENDING RESULTS"
          yield result
        end
      end
      acquired.each do |db|
        #puts "Querying: #{db.inspect}"
        begin
        q = db.aquery(query)
        rescue => e
          p e
          next
        end
        q.errback { |r| puts "ERROR in #{query} on #{db.inspect}:\n#{r}"; check_finish.call }
        q.callback do |r|
          #puts "Partial results: #{r.size}"
          result += r.each.to_a
          check_finish.call
          #puts "Bye"
        end
      end
    end
  end

end
