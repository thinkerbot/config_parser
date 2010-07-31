require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/option'

class OptionTest < Test::Unit::TestCase
  Option = ConfigParser::Option
  
  #
  # parse test
  #
  
  def test_parse_returns_value
    opt = Option.new
    assert_equal 'value', opt.parse('--opt', 'value')
  end
  
  def test_parse_calls_block_with_value
    opt = Option.new {|input| input.upcase }
    assert_equal 'VALUE', opt.parse('--opt', 'value')
  end
  
  def test_parse_shifts_value_from_argv_if_no_value_is_given
    opt = Option.new
    argv = ['a', 'b']
    
    assert_equal 'a', opt.parse('--opt', nil, argv)
    assert_equal ['b'], argv
  end
  
  def test_parse_raises_error_if_no_value_is_provided_and_argv_is_empty
    opt = Option.new
    e = assert_raises(RuntimeError) { opt.parse('--opt', nil, []) }
    assert_equal "no value provided for: --opt", e.message
  end
  
  #
  # to_s test
  #
  
  def test_to_s_adds_arg_name_to_formatted_string
    opt = Option.new(:long => 'long', :short => 's', :arg_name => 'ARGNAME', :desc => "description of key")
    expected = %q{
    -s, --long ARGNAME               description of key                         }
    assert_equal expected, "\n#{opt.to_s}"
  end
end