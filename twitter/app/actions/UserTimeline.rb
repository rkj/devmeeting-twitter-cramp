class UserTimeline < Cramp::Action
  use_fiber_pool# :size => 1000

  def start
    DB.new.db_for_user(params[:screen_name]) do |db, id, conns|
      if db == nil
        render "WON!"
        finish
        conns.each { |c| c.close }
      else
        #puts "Query on #{fiber.inspect}"
        q = db.aquery("SELECT * FROM statuses WHERE user_id = #{id} LIMIT 20")
        q.errback do |r|
          puts "Error123: #{r}"
          conns.each { |c| c.close }
          finish
        end
        q.callback do |r|
          render '['
          result = r.map do |row|
            %{{"created_at":"#{row['created_at']}","text":"#{row['text']}","id":#{row['id']}}}
          end.join(",\n")
          render result
          render ']'
          #puts "Releasing #{fiber.inspect} from #{db.inspect}"
          conns.each { |c| c.close }
          finish
        end
      end
    end
  end
end
