$: << 'lib'

require 'test/unit'
require 'worker_ant'

class TestWorkerAnt < Test::Unit::TestCase
  def setup
    Workerant.recipe do
      work :sammich, :cheese, :bread do
        puts "** sammich!"
      end

      work :cheese, :clean do
        puts "** cheese"
      end

      work :bread, :clean do
        puts "** bread"
      end

      work :clean do
        puts "** cleaning!"
      end
    end
  end

  def test_run
    p Workerant.instance.methods
    Workerant.run :sammich
  end
end
