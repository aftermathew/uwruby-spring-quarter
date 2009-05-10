require "test/unit"
require "simple_server"

class TestSimpleServer < Test::Unit::TestCase
  include SimpleServer

  def test_request_exist
    assert_nothing_raised(Exception){ r = Request.new }
  end
 
  def test_request_has_path
    assert_nothing_raised(Exception) { p = Request.new.path }
  end
  
  def test_request_has_method
    assert_nothing_raised(Exception) { m = Request.new.method  }
  end

  def test_response_exist
    assert_nothing_raised(Exception){ r = Response.new }
  end

  def test_request_has_status
    assert_nothing_raised(Exception) { r = Response.new.status }
  end

  def test_default_response_header
    assert_equal("HTTP/1.0 200 OK", Response.new.header)
  end


end
