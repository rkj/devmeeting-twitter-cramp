require 'em-synchrony/mysql2'

class Statuses < Cramp::Action
  def start
    render "Hello World!\n"
    #db = Mysql2::EM::Client.new
    #res = db.aquery("SELECT sleep(1) as mysql2_query;")
    #res.callback { |r| render "#{r.size}\nBye!\n" ; finish }
  end
end
