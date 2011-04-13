require 'test/unit'
require 'construct'
require 'mocha'

# http://thinkingdigitally.com/archive/capturing-output-from-puts-in-ruby/
require 'stringio'
module Kernel
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end
end

class Test::Unit::TestCase
  def assert_file(file)
    assert File.exists?(file)
  end

  def assert_no_file(file)
    assert !File.exists?(file)
  end
end

require 'powder/cli'
require 'powder/version'
def reset_powpath(path)
  Powder::CLI.__send__(:remove_const, 'POWPATH')
  Powder::CLI.const_set('POWPATH', path.to_s)
  path
end