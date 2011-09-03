class Hello < Cramp::Action
  def start
    render "Hello World!\n"
    finish
  end
end

