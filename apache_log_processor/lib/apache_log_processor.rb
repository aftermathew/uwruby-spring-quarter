require 'pathname'
require 'fileutils'
require 'resolv'
require 'thread'
require 'yaml'

class ApacheLogProcessor
  VERSION = '1.0.0'
  CACHE_FILE_DEFAULT = './alp_cachepath'
  DEFAULT_NUM_THREADS = 25
  DEFAULT_MAX_CACHE_AGE = (24 * 60 * 60) #24 hours in seconds
  IP_PATTERN = /(\d+)\.(\d+)\.(\d+)\.(\d+)/
  DEFAULT_TIMEOUT = 0.5

  attr_accessor :num_threads, :cache, :max_cache_age, :logpath
  attr_accessor :cachepath, :my_timeout, :outfile, :parsed_data

  def initialize logpath
    @cache         = {}
    @logpath       = logpath
    @max_cache_age = DEFAULT_MAX_CACHE_AGE
    @num_threads   = DEFAULT_NUM_THREADS
    @my_timeout    = DEFAULT_TIMEOUT
    @log_data      = Queue.new
    @cache_mutex   = Mutex.new
    @parsed_data = []
    @cachepath=CACHE_FILE_DEFAULT
    @outfile = nil
  end

  def load_cache
     unless File.exist?(@cachepath)
       puts "Warning: Cache file not found, will create chache from scratch"
     else
       @cache = YAML::load(File.read(@cachepath))
     end
  end

  def save_cache_to_disk
    File.open(@cachepath, 'w') do |out|
      YAML.dump(@cache, out)
    end
  end

  def get_ip line
    line.match(IP_PATTERN)[0]
  end

  def get_name_with_ip_using_network ip
    begin
      timeout(@my_timeout) {
        name = Resolv.getname(ip)
        add_ip_and_name_to_cache(ip, name)
        name
      }
    rescue Timeout::Error, Resolv::ResolvError, Resolv::ResolvTimeout
      nil
    end
  end

  def cache_record_should_be_removed record
    ((Time.now - record[:created_at]) > @max_cache_age)
  end

  def get_name_with_ip_using_cache ip
    @cache_mutex.synchronize do
      return nil unless @cache[ip]

      if(cache_record_should_be_removed @cache[ip])
        #not really needed, but it's nice to clear this stuff out at somepoint
        cache[ip] = nil
      else
        cache[ip][:name]
      end
    end
  end

  def add_ip_and_name_to_cache ip, name
    @cache_mutex.synchronize{ @cache[ip] = Hash[:name, name,
                                                :created_at, Time.new] }
  end

  def parse_line line
    ip = get_ip line

    name = get_name_with_ip_using_cache(ip) ||
      get_name_with_ip_using_network(ip) ||
      ("Cannot find name for " + ip)

    line.gsub(IP_PATTERN, name)
  end

  def read_logpath
    f = File.new(@logpath)
    f.each{ |line|
      line = "#{f.lineno}.  #{line}"
      @log_data << Hash[ :line_num, f.lineno - 1,
                         :line, line ]
    }
  end

  def run_line line_num, line
    @parsed_data[line_num] = parse_line line
  end

  def write_out
    if @outfile
      File.open(@outfile, 'w') do |out|
        @parsed_data.each{ |index| out.puts index }
      end
    else
      @parsed_data.each{ |index| p index }
    end
  end

  def run
    load_cache
    read_logpath
    consumers = []
    (0..@num_threads).each do |num|
      consumers << Thread.new do
        until(@log_data.empty?)
          data = @log_data.pop
          run_line(data[:line_num], data[:line])
        end
      end
    end

    while(@log_data.size > 1000) do
      sleep(5)
      p "#{@log_data.size} lines left"
    end

    consumers.each{ |c| c.join }
    save_cache_to_disk
  end
end
