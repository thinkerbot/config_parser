require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/option'

class OptionTest < Test::Unit::TestCase
  Option = ConfigParser::Option
  
  #
  # parse test
  #
  
  def test_parse_calls_block_with_value
    value_in_block = false
    opt = Option.new(:arg_name => 'ARG') {|input| value_in_block = input }

    opt.parse('--switch', 'value', [])
    assert_equal 'value', value_in_block
  end
  
  def test_parse_pulls_value_from_argv_if_no_value_is_given
    value_in_block = false
    opt = Option.new(:arg_name => 'ARG') {|input| value_in_block = input }

    argv = ['value']
    opt.parse('--switch', nil, argv)
    assert_equal 'value', value_in_block
    assert_equal [], argv
  end
  
  def test_parse_returns_value_if_no_block_is_given
    opt = Option.new(:arg_name => 'ARG')
    assert_equal 'value', opt.parse('--switch', 'value', [])
  end
  
  def test_parse_returns_block_value
    opt = Option.new(:arg_name => 'ARG') {|value| 'return value' }
    assert_equal 'return value', opt.parse('--switch', 'value', [])
  end
  
  def test_parse_raises_error_if_no_value_is_provided_and_argv_is_empty
    opt = Option.new(:arg_name => 'ARG')
    
    e = assert_raises(RuntimeError) { opt.parse('--switch', nil, []) }
    assert_equal "no value provided for: --switch", e.message
  end
  
  #
  # to_s test
  #
  
  def test_to_s_formats_option_for_the_command_line
    opt = Option.new(:long => 'long', :arg_name => 'KEY')
    assert_equal "        --long KEY                                                              ", opt.to_s
    
    opt = Option.new(:long => 'long', :short => 's', :arg_name => 'KEY', :desc => "description of key")
    assert_equal "    -s, --long KEY                   description of key                         ", opt.to_s
  end
  
  def test_to_s_wraps_long_descriptions
    opt = Option.new(:long => 'long', :desc => "a really long description of key " * 4)
    
    expected = %q{
        --long VALUE                 a really long description of key a really  
                                     long description of key a really long      
                                     description of key a really long           
                                     description of key                         }
                                     
    assert_equal expected, "\n" + opt.to_s
  end
  
  def test_to_s_indents_long_headers
    opt = Option.new(
      :short => 's',
      :long => '--a:nested:and-really-freaky-long-option', 
      :desc => "a really long description of key " * 2)
      
    expected = %q{
    -s, --a:nested:and-really-freaky-long-option VALUE                          
                                     a really long description of key a really  
                                     long description of key                    }
                                     
    assert_equal expected, "\n" + opt.to_s
  end
end