
$: << 'lib'

require 'test/unit'
require 'worker_bee'

class TestWorkerBee < Test::Unit::TestCase
  def setup
    Workerbee.recipe do
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

  def test_class_responds_to_recipe
    assert(Workerbee.respond_to?('recipe'))
  end


  def test_responds_to_work
    assert(Workerbee.respond_to?('work'))
  end

  def test_recipe_calls_block
    assert_raises RuntimeError do
      Workerbee.recipe do
        raise "throw me"
      end
    end
  end

  def test_work_has_not_run_by_default
    assert(!Workerbee.find_work(:sammich).has_run)
  end

  def test_work_is_marked_after_running
    clean = Workerbee.find_work(:clean)
    clean.run
    assert(clean.has_run)
  end

  def test_work_calls_its_deps
    bread = Workerbee.find_work(:bread)
    bread.run
    assert(Workerbee.find_work(:clean).has_run)
  end

  def test_responds_to_findwork
    assert(Workerbee.respond_to?('find_work'))
  end

  def test_task_names_recognized
    assert(Workerbee.find_work(:clean))
    assert(Workerbee.find_work(:sammich))
    assert(Workerbee.find_work(:bread))
    assert(Workerbee.find_work(:cheese))
  end

  def assert_run_defined
    assert(Workerbee.respond_to('run'))
  end

  def test_run
    Workerbee.run :sammich
  end
end
