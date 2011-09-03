require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

#$db = EventMachine::Synchrony::ConnectionPool.new(size: 1000) do
#end
class Statuses < Cramp::Action
  def start
    render "Hello World!\n"
    time = Time.now
    db = Mysql2::EM::Client.new(:host => "10.1.1.10", :username => "devcamp", :password => "devcamp", :database => "twitter1")
    res = db.aquery("SELECT * FROM users;")
    res.callback { |r| render "#{r.each.to_a}\n[#{Time.now - time}] Bye!\n" ; finish }
  end
end

