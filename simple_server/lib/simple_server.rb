require 'gserver'
require 'thread'
require 'pathname'

module SimpleServer
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
    
    def add string
      @request_string += string
    end
    
    def response_header num
      response = "HTTP/1.0 #{num} #{@@status_strings[num]}\r\n"
      response += "Server: SimpleRubyServer\r\n"        
      if((200..299) == num)
        response += "Last-Modified: #{@path.mtime}\r\n"
      end
      response += "\r\n"
    end
    
    def parse_header
      if @io.gets =~ /^(\S+)\s+(\S+)\s+(\S+)/
        @method = $1
        @path = Pathname.new $2.sub(/\A\//, '')
        dont_care = $3
      end
    end
        
    def generate_response
      #parse the first line:
      parse_header
      
      unless @method == "GET"
        @io << response_header(400)
        return
      end

      unless @path.exist? && @path.file?
        @io << response_header(404)
        return
      end

      @io << response_header(200)

      case @path.extname
      when '.erb'
        # run erb on the file and put the output of that in to the body

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
      request.generate_response
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
