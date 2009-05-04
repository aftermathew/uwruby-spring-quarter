require 'pathname'
require 'fileutils'
require 'resolv'

class ApacheLogProcessor
  VERSION = '1.0.0'
  CACHE_FILE_DEFAULT = './alp_cachepath'
  DEFAULT_NUM_THREADS = 20
  @@ALP_CacheEntry = Struct.new(:name, :created_at)

  attr_accessor :num_threads, :cache

  def initialize logpath
    @cache = {}
    @logpath = logpath
    @num_threads = DEFAULT_NUM_THREADS
  end

  def load_cache cachepath=CACHE_FILE_DEFAULT
     unless File.exist?(cachepath)
       raise "Warning: Cache file not found, will create chache from scratch"
     else
       @cache = YAML::load(File.read(cachepath))
     end
  end

  def get_ip line
    line.match(/(\d+)\.(\d+)\.(\d+)\.(\d+)/)[0]
  end

  def get_name_with_ip_using_network ip
    Resolv.getname(ip)
  end

  def get_name_with_ip_using_cache ip
    @cache[ip][:name]
  end

  def add_ip_and_name_to_cache ip, name
    @cache[ip] = @@ALP_CacheEntry.new(name, Time.new)
  end

  def read_logpath
  end

  def save_cache_to_disk
  end

  def resolve_name ip
  end

  def parse_options options
  end
end
