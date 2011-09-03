# Check out https://github.com/joshbuddy/http_router for more information on HttpRouter
HttpRouter.new do
  add('/').to(Hello)
  add('/hi').to(HiStatuses)
	add('/statuses/home_timeline').to(HomeTimeline)
	add('/statuses/user_timeline').to(UserTimeline)
	add('/statuses/update').to(Update)
end
