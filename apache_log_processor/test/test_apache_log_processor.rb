require "test/unit"
require "apache_log_processor"
require 'fileutils'

class TestApacheLogProcessor < Test::Unit::TestCase
  def setup
    @alp = ApacheLogProcessor.new 'test/sampleinput.log'
    @ip = '208.77.188.166'
    @name = 'www.example.com'
    @test_line = '208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
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
    ip = @alp.get_ip @test_line
    assert_equal(@ip, ip)
  end

  def test_example_ip_results_in_example_name
    assert_equal(@name, @alp.get_name_with_ip_using_network('208.77.188.166'))
  end

  def test_fake_ip_resutls_in_nil_name
    assert_nil(@alp.get_name_with_ip_using_network('127.0.0.2'))
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

  def test_that_cache_retires_old_data
    @alp.add_ip_and_name_to_cache(@ip, @name)
    @alp.cache[@ip][:created_at] -= @alp.max_cache_age + 1
    assert_nil(@alp.get_name_with_ip_using_cache(@ip))
    assert_nil(@alp.cache[@ip])
  end

  def test_single_line_parse_replaces_ip_with_name
    assert_equal("#{@name}" +
                 ' - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342',
                 @alp.parse_line(@test_line))
  end

  def test_read_logpath_puts_file_data_into_log_data
    @alp.read_logpath
    assert(@alp.instance_eval("@log_data").size > 0)
  end

  def test_run
    @alp.run

    ApacheLogProcessor.new('test/long_testfile.log').run

  end

  def teardown
    if(File.exist?(ApacheLogProcessor::CACHE_FILE_DEFAULT)) then
      FileUtils.rm(ApacheLogProcessor::CACHE_FILE_DEFAULT)
    end
  end
end
