require 'pathname'
require 'fileutils'
require 'resolv'

class ApacheLogProcessor
  VERSION = '1.0.0'
  CACHE_FILE_DEFAULT = './alp_cachepath'
  DEFAULT_NUM_THREADS = 20
  DEFAULT_MAX_CACHE_AGE = (24 * 60 * 60) #24 hours in seconds
  IP_PATTERN = /(\d+)\.(\d+)\.(\d+)\.(\d+)/

  @@CacheEntry = Struct.new(:name, :created_at)

  attr_accessor :num_threads, :cache, :max_cache_age

  def initialize logpath
    @max_cache_age = DEFAULT_MAX_CACHE_AGE
    @cache = {}
    @logpath = logpath
    @num_threads = DEFAULT_NUM_THREADS
    @log_data = []
    @parsed_data = []
  end

  def load_cache cachepath=CACHE_FILE_DEFAULT
     unless File.exist?(cachepath)
       raise "Warning: Cache file not found, will create chache from scratch"
     else
       @cache = YAML::load(File.read(cachepath))
     end
  end

  def get_ip line
    line.match(IP_PATTERN)[0]
  end

  def get_name_with_ip_using_network ip
    begin
      name = Resolv.getname(ip)
      add_ip_and_name_to_cache(ip, name)
      name
    rescue
      nil
    end
  end

  def cache_record_should_be_removed record
    ((Time.now - record[:created_at]) > @max_cache_age)
  end

  def get_name_with_ip_using_cache ip
    return nil unless cache[ip]

    if(cache_record_should_be_removed cache[ip])
      #not really needed, but it's nice to clear this stuff out at somepoint
      cache[ip] = nil
    else
      cache[ip][:name]
    end
  end

  def add_ip_and_name_to_cache ip, name
    @cache[ip] = @@CacheEntry.new(name, Time.new)
  end

  def parse_line line
    ip = get_ip line

    name = get_name_with_ip_using_cache(ip) ||
      get_name_with_ip_using_network(ip) ||
      ("Cannot find name for " + ip)

    line.gsub(IP_PATTERN, name)
  end

  def read_logpath
    @log_data = File.readlines(@logpath)
  end

  def save_cache_to_disk outfile
    File.open(outfile, 'w') do |out|
      YAML.dump(cache, out)
    end
  end

  def run_line line_num
    @parsed_data[line_num] = parse_line @log_data[line_num]
  end

  def run
    read_logpath
    @log_data.each_index{ |num| run_line(num) }
    @parsed_data.each{ |index| p index }
  end

  def parse_options options
  end
end
