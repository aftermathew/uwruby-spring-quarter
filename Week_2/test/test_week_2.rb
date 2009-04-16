require 'test/unit'
require 'week_2'

class Week2Homework < Test::Unit::TestCase
  def setup
    @week2 = Week2.new
  end

  def test_try_to_get_the_secret
    # What do you need from @week2 to get at the instance variable?
    assert_equal('secret', eval("@i_am_hidden", @week2.fixme))
  end

  def test_alias_a_method
    assert !Week2.instance_methods.include?(:available)

    # Try to alias a method inside Week2 here

    week2 = Week2.new
    assert week2.methods.include?("available")
    assert_equal('not a secret', week2.available)
  end

  def test_find_the_secret_again
    # Try to grab the secret instance variable without using eval()
    assert_equal('secret', @week2.fixme('@i_am_hidden'))
  end

  # This test should only take a few lines of code to fix!
  def test_week2_responds_to_lots_of_methods
    assert ('a'..'z').all? { |letter| @week2.respond_to?(:"letter_#{letter}") }

    expected_responses = ('a'..'z').map { |letter|
      @week_to.send(:"letter_#{letter}")
    }
    expected_responses = ('a'..'z').map { |letter|
      "the letter #{letter}"
    }
    assert_equal(expected_responses, actual_responses)
  end

  ###
  # modify week_2.rb to get this test to pass.
  def test_that_the_block_gets_evaled
    foo = nil
    @week2.instance_eval_a_block do
      foo = hello
    end
    assert_equal 'world', foo
  end
end
