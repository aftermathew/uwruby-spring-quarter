require 'singleton'
class Workerant
  include Singleton
  def initialize
    @has_run= {}
  end

  def self.work identifier, *args, &block
    deps_string = ""
    args.each{ |arg| deps_string +="#{arg} depth + 1; " }
    if(deps_string.size == 0) then deps_string = nil end

    block_method = "#{identifier}_block"
    define_method(block_method, block)

    function_string = <<-FUNCTION
     def #{identifier} depth=0
       unless(@has_run[:#{identifier}] != nil)
          @has_run[:#{identifier}] = 1
          puts "  " * depth  + "Running #{identifier}"
          #{deps_string}
          self.send(:#{block_method})
       else
          puts "  " * depth+ "not running #{identifier} - already met dependency"
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
