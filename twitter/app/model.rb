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
	@@db = Twit::ConnectionPool.new(size: 1) do
		(1..4).map do |i|
		Mysql2::EM::Client.new(:host => "10.1.1.10", :username => "devcamp", :password => "devcamp", :database => "twitter#{i}")
		end
	end

	def db_for_user(name)
		counter = 4
    ok = false
		@@db.execute(true) do |acquired, fiber|
      #puts "me acquired"
			acquired.each do |db|
				db.aquery("SELECT id FROM users WHERE screen_name = '#{name}'").callback do |r|
					counter -= 1
					if r.size > 0
						r.each do |userRow|
              ok = true
							yield db, userRow['id']
						end
					end
					if !ok && counter == 0
						yield nil, nil
					end
          if counter <= 0
            #puts "Me release"
            @@db.release(fiber)
          end
				end
			end
		end
	end

  def test
    puts "TEST"
  end

end
