require "test/unit"
require "apache_log_processor"
require 'fileutils'

class TestApacheLogProcessor < Test::Unit::TestCase
  def setup
    @alp = ApacheLogProcessor.new 'sampleinput.log'
    @ip = '208.77.188.166'
    @name = 'www.example.com'
  end

  def test_cache_load_raises_when_file_not_there
    assert_raise RuntimeError do
      @alp.load_cache
    end
  end

  def test_cache_load_no_raise_when_file_there
    FileUtils.touch(ApacheLogProcessor::CACHE_FILE_DEFAULT)
    assert_nothing_raised {@alp.load_cache }
  end

  def test_parse_line_returns_correct_ip
    ip = @alp.get_ip '208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    assert_equal(@ip, ip)
  end

  def test_example_ip_results_in_example_name
    assert_equal(@name, @alp.get_name_with_ip_using_network('208.77.188.166'))
  end

  def test_adding_to_cache_does_just_that
    @alp.add_ip_and_name_to_cache(@ip, @name)
    assert(@alp.cache[@ip])
    assert_equal(@name, @alp.cache[@ip][:name])
  end

  def test_searching_for_an_ip_in_the_cache_works
    @alp.add_ip_and_name_to_cache(@ip, @name)
    assert_equal(@name, @alp.get_name_with_ip_using_cache(@ip))
  end

  def teardown
    if(File.exist?(ApacheLogProcessor::CACHE_FILE_DEFAULT)) then
      FileUtils.rm(ApacheLogProcessor::CACHE_FILE_DEFAULT)
    end
  end
end
