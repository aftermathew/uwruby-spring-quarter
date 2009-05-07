require 'pathname'
require 'fileutils'
require 'resolv'
require 'thread'

class ApacheLogProcessor
  VERSION = '1.0.0'
  CACHE_FILE_DEFAULT = './alp_cachepath'
  DEFAULT_NUM_THREADS = 25
  DEFAULT_MAX_CACHE_AGE = (24 * 60 * 60) #24 hours in seconds
  IP_PATTERN = /(\d+)\.(\d+)\.(\d+)\.(\d+)/
  DEFAULT_TIMEOUT = 0.5

  @@CacheEntry = Struct.new(:name, :created_at)

  attr_accessor :num_threads, :cache, :max_cache_age, :logpath, :cachepath

  def initialize logpath
    @max_cache_age = DEFAULT_MAX_CACHE_AGE
    @cache = {}
    @logpath = logpath
    @num_threads = DEFAULT_NUM_THREADS
    @timeout = DEFAULT_TIMEOUT
    @log_data = []
    @cache_mutex = Mutex.new
    @data_mutex = Mutex.new
    @parsed_data = []
    @cachepath=CACHE_FILE_DEFAULT
  end

  def load_cache
     unless File.exist?(@cachepath)
       raise "Warning: Cache file not found, will create chache from scratch"
     else
       @cache_mutex.synchronize{ @cache = YAML::load(File.read(@cachepath)) }
     end
  end

  def get_ip line
    line.match(IP_PATTERN)[0]
  end

  def get_name_with_ip_using_network ip
    begin
      timeout(@timeout) {
        name = Resolv.getname(ip)
        add_ip_and_name_to_cache(ip, name)
        name
      }
    rescue Timeout::Error, Resolv::ResolvError
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
    @cache_mutex.synchronize{ @cache[ip] = @@CacheEntry.new(name, Time.new) }
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

  def save_cache_to_disk outfile
    File.open(outfile, 'w') do |out|
      YAML.dump(cache, out)
    end
  end

  def run_line line_num, line
    @parsed_data[line_num] = parse_line line
  end

  def _pop_line
    @data_mutex.synchronize do
      @log_data.pop
    end
  end

  def run
    read_logpath
    consumers = []
    (0..@num_threads).each do |num|
      consumers << Thread.new do
        while((data = _pop_line))
          run_line(data[:line_num], data[:line])
        end
      end
    end

    while(@log_data.size > 1000) do
      sleep(5)
      p "#{@log_data.size} lines left"
    end

    consumers.each{ |c| c.join }

    @parsed_data.each{ |index| p index }
  end

  def parse_options options
  end
end
