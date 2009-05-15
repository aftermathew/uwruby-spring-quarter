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

  class Response
    attr_accessor :header, :body

    def initialize
      @header = ""
      @body = ""
    end

    def write_out
      "#{@header}Content-Length:#{@body.size}\r\n\r\n#{@body}\r\n"
    end

    alias to_s write_out

  end

  class Request
    attr_accessor :method, :path
    @@mime_types = {
      '.html' => "text/html",
      '.htm' => "text/html",
      '.erb' => "text/html"
    }

    @@status_strings = {
      200 => "OK",
      400 => "Bad Request",
      404 => "Not Found",
      500 => "Internal Server Error"
    }

    def initialize io
      @io = io
      @response = Response.new
    end

    def response_header num
      @response.header = "HTTP/1.0 #{num} #{@@status_strings[num]}\r\n"
      @response.header += "Server: SimpleRubyServer\r\n"
      unless((200..299) === num)
        @response.body = "Uh oh: Response #{num}: #{@@status_strings[num]}"
      end
      @response
    end

    def parse_header
      if @io.gets =~ /^(\S+)\s+(\S+)\s+(\S+)/
        @method = $1.upcase
        @path = $2.sub(/\A\//, '')
        @pathname = Pathname.new @path
        dont_care = $3
      end
    end

    def handle_servlets servlets
      if servlets[@path]
        response_header(200)
        @response.body = servlets[@path].call
        @io << @response
        true
      end
      false
    end

    def method_handled?
      unless @method == "GET"
        @io << response_header(400)
        false
      end
      true
    end

    def file_exist?
      if @pathname.exist? && @pathname.file?
        return true
      end
      @io << response_header(404)
      return false
    end

    def add_content_type
      @@mime_types[@pathname.extname] ? @response.header <<
        "Content-Type: #{@@mime_types[@pathname.extname]}\r\n" : nil
    end

    def generate_response servlets = {}
      parse_header
      return unless method_handled?
      return if handle_servlets servlets
      return unless file_exist?

      response_header(200)
      add_content_type
      if @pathname.extname == '.erb'
        # run erb on the file and put the output of that in to the body
        erbfile = ERB.new  @pathname.read
        @response.body = erbfile.result(binding)
        @io << @response
      else
        #open file and put the text into the body
        #just put the file into the body...
          @response.body << @pathname.read
          @io << @response
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
      io.print "ERROR: #{e.to_s} #{e.backtrace}\r\n"
    end
  end
end

class SimpleGServer < GServer
  VERSION = '1.0.0'
  include SimpleServer

  def initialize(port=8080, *args)
    super(port, *args)
#    @audit = true
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
          @threads.delete Thread.current
        end
      end
    end
  end
end

