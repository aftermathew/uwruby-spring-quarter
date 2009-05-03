require 'thread'
class Work
  attr_accessor :id,:dependencies, :block, :has_run
  def run depth=0
    @mutex.synchronize do
      unless @has_run
        threads = []
        puts "  " * depth  + "Running #{id}"
        dependencies.each do |dep|
          threads << Thread.new {
            Workerbee.find_work(dep).run(depth + 1)
          }
        end
        threads.each{ |thread| thread.join }
        block.call
        @has_run = true
      else
        puts "  " * depth + "not running #{id} - already met dependency"
      end
    end
  end

  def initialize identifier, *args, &block
    @id = identifier
    @dependencies = args
    @block = block
    @has_run = false
    @mutex = Mutex.new
  end
end

module Workerbee
  VERSION = '1.0.0'
  @works = {}
  def self.work identifier, *args, &block
    @works[identifier] = Work.new(identifier, *args, &block)
  end

  def self.recipe &block
    module_eval &block
  end

  def self.find_work to_find
    return @works[to_find]
  end

  def self.run to_run=nil
    to_run ? find_work(to_run).run : @works.each{|key, value| value.run}
  end
end
