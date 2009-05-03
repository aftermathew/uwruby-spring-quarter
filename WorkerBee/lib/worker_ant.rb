require 'singleton'
require 'thread'

class Workerant
  include Singleton
  def initialize
    @has_run = {}
    @mutexes = {}
  end

  def self.work identifier, *args, &block
    deps_string = ""
    args.each{ |arg|
      deps_string += "threads << Thread.new{ #{arg} depth + 1 }; "
    }

    define_method("#{identifier}_block", block)

    function_string = <<-FUNCTION
     def #{identifier} depth=0
       puts "calling #{identifier}"
       threads = []
       @mutexes[:#{identifier}] ||= Mutex.new
       @mutexes[:#{identifier}].synchronize do
         unless(@has_run[:#{identifier}])
           @has_run[:#{identifier}] = 1
           puts "  " * depth  + "Running #{identifier}"
           #{deps_string}
           threads.each { |t| t.join }
           self.send(:#{identifier}_block)
         else
           puts "  " * depth + "not running #{identifier} - already met dependency"
         end
       end
     end
    FUNCTION

    instance.instance_eval function_string
  end

  class << self; alias recipe class_eval  end

  def self.run to_run
    instance.send(to_run)
  end
end
