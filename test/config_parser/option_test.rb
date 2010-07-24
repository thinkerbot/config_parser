require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/option'

class OptionTest < Test::Unit::TestCase
  Option = ConfigParser::Option
  
  #
  # initialize tests
  #
  
  def test_initialization
    o = Option.new(:long => 'key')
    assert_equal '--key', o.long
    assert_equal nil, o.short
    assert_equal nil, o.arg_name
    assert_equal nil, o.desc
    assert_equal nil, o.callback
  end
  
  def test_initialization_with_attributes
    b = lambda {}
    o = Option.new(:long => 'long', :short => 's', :desc => 'some desc', :arg_name => 'name', &b)
    assert_equal '--long', o.long
    assert_equal '-s', o.short
    assert_equal 'name', o.arg_name
    assert_equal 'some desc', o.desc
    assert_equal b, o.callback
  end
  
  def test_initialization_formats_flags_as_necessary
    o = Option.new(:long => 'long', :short => 's')
    assert_equal '--long', o.long
    assert_equal '-s', o.short
    
    o = Option.new(:long => '--long', :short => '-s')
    assert_equal '--long', o.long
    assert_equal '-s', o.short
  end
  
  def test_initialization_raises_error_for_bad_flags
    e = assert_raises(ArgumentError) { Option.new(:long => '') }
    assert_equal "invalid long flag: --", e.message
    
    e = assert_raises(ArgumentError) { Option.new(:short => '--long') }
    assert_equal "invalid short flag: --long", e.message
    
    e = assert_raises(ArgumentError) { Option.new(:short => '') }
    assert_equal "invalid short flag: -", e.message
  end
  
  def test_options_may_be_initialized_with_no_long_flag
    opt = Option.new
    assert_equal nil, opt.long
  end
  
  #
  # flags test
  #
  
  def test_flags_returns_the_non_nil_long_and_short_flags
    opt = Option.new(:long => 'long')
    assert_equal ["--long"], opt.flags
    
    opt = Option.new(:long => 'long', :short => 's')
    assert_equal ["--long", '-s'], opt.flags
    
    opt = Option.new
    assert_equal [], opt.flags
  end
  
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
        --long                       a really long description of key a really  
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
    -s, --a:nested:and-really-freaky-long-option                                
                                     a really long description of key a really  
                                     long description of key                    }
                                     
    assert_equal expected, "\n" + opt.to_s
  end
end