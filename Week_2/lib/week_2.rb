class Week2
  VERSION = '1.0.0'

  attr_accessor :not_hidden

  def initialize
    @i_am_hidden = 'secret'
    @not_hidden = 'not a secret'
  end

  def instance_eval_a_block &block
    self.instance_eval &block
  end

  private
  def hello
    "world"
  end
end
