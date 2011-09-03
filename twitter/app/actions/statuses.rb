require 'em-synchrony/mysql2'
require 'cramp/exception_handler'

#$db = EventMachine::Synchrony::ConnectionPool.new(size: 1000) do
#end
class Statuses < Cramp::Action
  def fib(x)
    return 1 if x <= 2
    fib(x-1) + fib(x-2)
  end
  def start
    render "Hello World!\n"
    time = Time.now
    db = Mysql2::EM::Client.new
    res = db.aquery("SELECT sleep(30) as mysql2_query;")
    res.callback { |r| render "#{r.size}\n[#{Time.now - time}] Bye!\n" ; finish }
  end
end

