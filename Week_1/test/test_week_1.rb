require 'test/unit'
require 'week_1'

class Week1Homework < Test::Unit::TestCase
  def test_dotify_makes_dots
    assert_equal("r.u.b.y", "ruby".dotify)
  end

  def test_dotify_makes_other_characters
    assert_equal("r*u*b*y", "ruby".dotify('*'))
  end

  def test_dotify_was_aliased_to_period!
    assert_equal("r.u.b.y", "ruby".period!)
    assert_equal("ruby".dotify, "ruby".period!)
  end

  def test_singleton_method
    string1 = "hello"
    string2 = "world"

    # Add code HERE
    def string1.only_one
      "There can be only one."
    end

    assert string1.respond_to?(:only_one)
    assert !string2.respond_to?(:only_one)
  end

  def test_module_extend_adds_a_method
    string = "Hello world"

    string.extend(Week1Module)

    assert_equal("uw ruby!", string.uw_ruby)
  end

  # Try filling out the method in week_1.rb to solve this
  def test_call_red_or_blue
    string1 = "Hello world"
    string2 = "Hello world again"

    # Add the "red" method to string1
    class << string1
      def red; "red"; end
    end

    # Add the "blue" method to string2
    class << string2
      def blue; "blue"; end
    end

    assert string1.respond_to?(:red)
    assert !string1.respond_to?(:blue)
    assert !string2.respond_to?(:red)
    assert string2.respond_to?(:blue)
    assert_equal "red", string1.red_or_blue
    assert_equal "blue", string2.red_or_blue
  end

  def test_send
    assert_equal([5, 6, 8], send_map(2, 3, :+, :*, :**))
  end
end
