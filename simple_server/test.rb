require 'lib/simple_server.rb'

s = SimpleGServer.new
s.audit = true

s.add_servlet "servlet/time" do
  Time.now.to_s
end

s.start

t = SimpleTServer.new
t.start

until(false)do sleep(1) end
