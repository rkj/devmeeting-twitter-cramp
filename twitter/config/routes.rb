# Check out https://github.com/joshbuddy/http_router for more information on HttpRouter
HttpRouter.new do
  add('/').to(Hello)
  add('/hi').to(HiStatuses)
end
