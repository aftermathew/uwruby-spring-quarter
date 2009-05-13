require 'gserver'
require 'thread'
require 'pathname'
require 'erb'
require 'pp'
require 'socket'

module SimpleServer
  attr_accessor :servlets

  def add_servlet path, &block
    @servlets ||= {}  
    @servlets[path] = block
  end

  def remove_servlet path
    @servlets ||= {}
    @servlets.delete path
  end
  
  class Request
    attr_accessor :method, :path, :request_string

    @@status_strings = {
      200 => "OK",
      400 => "Bad Request",
      404 => "Not Found",
      500 => "Internal Server Error"
    }

    def initialize io
      @io = io
    end

    def response_header num
      response = "HTTP/1.0 #{num} #{@@status_strings[num]}\r\n"
      response += "Server: SimpleRubyServer\r\n"
      if((200..299) == num)
        response += "Last-Modified: #{@path.mtime}\r\n"
      end
      response += "\r\n"
      warn response
      response
    end

    def parse_header
      if @io.gets =~ /^(\S+)\s+(\S+)\s+(\S+)/
        @method = $1
        @path = Pathname.new $2.sub(/\A\//, '')
        dont_care = $3
        warn "path is #{@path}"
      end
    end

    def generate_response servlets = {}
      #parse the first line:
      parse_header

      unless @method == "GET"
        @io << response_header(400)
        return
      end

      if servlets[@path.to_s]
        response = response_header(200)
        response <<  servlets[@path.to_s].call
        @io << response
        return
      end
        
      unless @path.exist? && @path.file?
        @io << response_header(404)
        return
      end

      @io << response_header(200)

      if @path.extname == '.erb'
        # run erb on the file and put the output of that in to the body
        erbfile = ERB.new  @path.read
        @io << erbfile.result(binding)
      else
        #open file and put the text into the body
        #just put the file into the body...
          @io << @path.read
      end
    end
  end

  def respond io
    begin
      request = Request.new io
      @servlets ||= {}
      request.generate_response @servlets
    rescue Exception => e
      io.print "HTTP/1.0 500 Internal Server Error\r\n"
      io.print "ERROR: #{e.to_s}\r\n"
    end
  end
end

class SimpleGServer < GServer
  VERSION = '1.0.0'
  include SimpleServer

  def initialize(port=8080, *args)
    super(port, *args)
    @audit = true
  end

  def serve(io)
    respond io
  end
end

class SimpleTServer 
  include SimpleServer
  
  def initialize port=8081, num_threads = 5
    @port = port
    @server = TCPServer.new(@port)
    @queue = Queue.new
    @threads = []
    @num_threads = num_threads
  end
  
  def start
    Thread.new do
      while session = @server.accept
        until @threads.size < @num_threads
          Thread.pass
       end     

        @threads << Thread.new(session) do |my_session|
         respond my_session
         my_session.close
          pp @threads
          @threads.delete Thread.current
          pp @threads
        end
      end
    end
  end
end

