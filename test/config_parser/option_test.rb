require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/option'

class OptionTest < Test::Unit::TestCase
  Option = ConfigParser::Option
  
  attr_reader :opt
  
  def setup
    @opt = Option.new
  end
  
  #
  # parse test
  #
  
  def test_parse_shifts_value_from_argv_if_no_value_is_given
    value_in_block = nil
    opt = Option.new(:callback => lambda {|value| value_in_block = value })
    
    argv = ['a', 'b']
    opt.parse('--opt', nil, argv)
    
    assert_equal 'a', value_in_block
    assert_equal ['b'], argv
  end
  
  def test_parse_uses_default_value_if_no_value_is_available_and_optional
    value_in_block = nil
    opt = Option.new(
      :default => 'value',
      :optional => true,
      :callback => lambda {|value| value_in_block = value }
    )
    
    argv = ['-a']
    opt.parse('--opt', nil, argv)
    
    assert_equal 'value', value_in_block
    assert_equal ['-a'], argv
  end
  
  def test_parse_shifts_value_from_argv_if_a_value_is_available
    value_in_block = nil
    opt = Option.new(
      :default => 'value',
      :optional => true,
      :callback => lambda {|value| value_in_block = value }
    )
    
    argv = ['a', 'b']
    opt.parse('--opt', nil, argv)
    
    assert_equal 'a', value_in_block
    assert_equal ['b'], argv
  end
  
  def test_parse_raises_error_if_no_value_is_provided_and_argv_is_empty
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