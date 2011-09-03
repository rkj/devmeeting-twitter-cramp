class UserTimeline < Cramp::Action
  use_fiber_pool :size => 1000

  def start
    DB.new.db_for_user(params[:screen_name]) do |db, id, pool, fiber|
      if db == nil
        render "WON!"
        finish
        pool.release(fiber)
      else
        #puts "Query on #{fiber.inspect}"
        db.aquery("SELECT * FROM statuses WHERE user_id = #{id}").callback do |r|
          render '['
          result = r.map do |row|
            %{{"created_at":#{row['created_at']},"text":#{row['text']},"id":#{row['id']}}}
          end.join(",\n")
          render result
          render ']'
          finish
          pool.release(fiber)
        end
      end
    end
  end
end
