module Week1Module
  VERSION = '1.0.0'

  def uw_ruby
    "uw ruby!"
  end
end

class String
  def red_or_blue
    return red if respond_to?(:red)
    return blue if respond_to?(:blue)
  end

  def dotify *args
    dot = (args.size > 0)? args[0] : '.'
    split('').join(dot)
  end

  alias :period! :dotify
end

def send_map *args
  (2..(args.size - 1)).map do |index|
    args[0].send(args[index], args[1])
  end
end
