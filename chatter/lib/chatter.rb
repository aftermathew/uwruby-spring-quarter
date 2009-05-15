require 'drb'
require 'drb/observer'
require 'thread'
require 'pp'

module ChatterGlobals
  @@URI = 'druby://localhost:31337'
end

class ChatterServer
  include DRb::DRbObservable
  include ChatterGlobals
  VERSION = '1.0.0'
  
  #get rid of this stupid change variable... and handle rooms
  def my_notify_observers room, *args
    if defined? @observer_peers
      for i in @observer_peers.dup
        begin
          i.update(*args) if(i.room == room)
        rescue
          delete_observer(i)
        end
      end
    end
  end
    
  def speak room, who, message
    @observer_peers
    
    my_notify_observers(room, who, message)    
  end

  def self.serve
    DRb.start_service(@@URI, ChatterServer.new)
    DRb.thread.join
  end
end


class ChatterClient
  include DRbUndumped 
  include ChatterGlobals
  
  attr_accessor :name, :room

  def initialize(name, service) 
    @name = name
    @service = service 
    @service.add_observer(self)
    @room = "default room"
  end 

  def join room
    @room = room
    @service.speak room, self, "has joined room #{room}"
    puts "You have joined the #{room} room."
  end

  def speak
    puts "Starting Chatter with name #{@name}"
    while((words = STDIN.gets))
      if(words =~ /\Ajoin:\s(\S+)/) 
        puts "regular!"
        join $1
        next
      end
      
      @service.speak @room, self, words.chomp
    end    
  end 

  def update(who, message) 
    puts "#{who.name}: #{message}" if(who != self)
  end 

  def self.chat name
    DRb.start_service
    server = DRbObject.new(nil, @@URI)
    chatter = ChatterClient.new(name, server)
    chatter.speak
  end
end


