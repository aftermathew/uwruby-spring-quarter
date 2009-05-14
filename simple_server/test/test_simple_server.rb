require "test/unit"
require "simple_server"

class String
  def gets
    self.split("\r\n")[0]
  end

  def << o
    concat o.to_s
  end
end


class TestSimpleServer < Test::Unit::TestCase
  include SimpleServer

  def setup
    @gserver = SimpleGServer.new(8080)
    @request_html = "GET /test/test.html HTTP/1.0\r\n\r\n"
  end

  def teardown
    @gserver.stop
  end

  def test_add_servlet
    @gserver.add_servlet "bad_servlet" do
      raise "FAIL!"
    end
    assert(@gserver.servlets["bad_servlet"])
    assert_raises(RuntimeError){
      @gserver.servlets["bad_servlet"].call
    }
  end

  def test_remove_servlet
    test_add_servlet
    @gserver.remove_servlet "bad_servlet"
    assert_nil(@gserver.servlets["bad_servlet"])
  end

  def test_response_has_body
    r = Response.new
    assert_nothing_raised do
      r.body = "hot body"
      body = r.body
    end
  end

  def test_response_has_header
    r = Response.new
    assert_nothing_raised do
      r.header = "hot head"
      body = r.header
    end
  end

  def test_response_to_s
    r = Response.new
    header = "this is a header"
    body = "body here dude"

    r.header = header
    r.body = body
    s = r.to_s

    assert(s.include? header)
    assert(s.include? body)
  end

  def parse_header
    @r = Request.new @request_html
    @r.parse_header
  end

  def test_request_parse_header
    parse_header
    assert_equal('GET', @r.method)
    assert_equal('test/test.html', @r.path)
  end

  def test_method_handles_get
    parse_header
    assert(@r.method_handled?)
  end

  def test_file_exist_check
    parse_header
    assert(@r.file_exist?)
    r = Request.new "GET FART/NOTREAL HTML/1.0\r\n"
    r.parse_header
    assert(!r.file_exist?)
  end

  def test_content_type
    parse_header
    header = @r.instance_eval { @response }.header
    assert(!(header.include?("Content-Type:")))
    assert(!(header.include?("text/html")))
    @r.add_content_type
    assert(header.include?("Content-Type:"))
    assert(header.include?("text/html"))
  end

  def do_actual_request server, port
    server.start
    session = TCPSocket.new('localhost', port)
    session.puts @request_html
    s = session.read
    session.close

    assert(s.include?('200 OK'))
    assert(s.include?('<html>'))
    assert(s.include?('</html>'))
    assert(s.include?("Content-Type:"))
    assert(s.include?("text/html"))
  end

  def test_gserver_request
    do_actual_request @gserver, 8080
  end

  def test_tserver_request
    tserver = SimpleTServer.new
    do_actual_request tserver, 8081
  end

  def test_servlet_request
    @gserver.add_servlet "servlet/time" do
      "<html><body>#{Time.now.to_s} Hoopla</body></html>"
    end

    @gserver.start

    session = TCPSocket.new('localhost', 8080)
    session.puts "GET /servlet/time HTML/1.0"
    s = session.read
    session.close

    assert(s.include?('200 OK'))
    assert(s.include?('<html>'))
    assert(s.include?('</html>'))
    assert(s.include?('Hoopla'))
  end


  def test_erb
    @gserver.start

    session = TCPSocket.new('localhost', 8080)
    session.puts "GET /test/test.html.erb HTML/1.0"
    s = session.read
    session.close

    assert(s.include?('	<li><b>hello</b></li>'))
    assert(s.include?('	<li><b>how</b></li>'))
    assert(s.include?('	<li><b>are</b></li>'))
    assert(s.include?('	<li><b>you</b></li>'))
  end

end

