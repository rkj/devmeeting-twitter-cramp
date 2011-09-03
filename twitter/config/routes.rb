# Check out https://github.com/joshbuddy/http_router for more information on HttpRouter
HttpRouter.new do
  add('/').to(Hello)
	add('/statuses/home_timeline.json').to(HomeTimeline)
	add('/statuses/user_timeline.json').to(UserTimeline)
	add('/statuses/update.json').to(Update)
end
