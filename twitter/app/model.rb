require 'em-synchrony/mysql2'
require 'cramp/exception_handler'


class DB
	@@db = EventMachine::Synchrony::ConnectionPool.new(size: 10) do
		(1..4).map do |i|
		Mysql2::EM::Client.new(:host => "10.1.1.10", :username => "devcamp", :password => "devcamp", :database => "twitter#{i}")
		end
	end

	def db_for_user(name)
		counter = 4
		@@db.execute(true) do |acquired|
			acquired.each do |db|
				db.aquery("SELECT id FROM users WHERE screen_name = '#{name}'").callback do |r|
					counter -= 1
					if r.size > 0
						r.each do |userRow|
							counter = -1
							yield db, userRow['id']
						end
					end
					if counter == 0
						yield nil, nil
					end
				end
			end
		end
	end

  def test
    puts "TEST"
  end

end
