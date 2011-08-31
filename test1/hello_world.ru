require "rubygems"
require 'cramp'

class HomeAction < Cramp::Action
  def start
    render "Hello World"
    finish
  end
end

# thin --timeout 0 -R hello_world.ru start
run HomeAction
