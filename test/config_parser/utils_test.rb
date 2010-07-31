require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/utils'

class ConfigParser::UtilsTest < Test::Unit::TestCase
  include ConfigParser::Utils

  attr_reader :config
  
  def setup
    @config = {}
  end

  #
  # LONG_FLAG test
  #
  
  def test_LONG_FLAG
    r = LONG_FLAG
    
    assert '--long' =~ r
    assert '--long-option' =~ r
    
    # non-matching
    assert 'arg' !~ r
    assert '-o' !~ r
    assert '--' !~ r
  end
  
  #
  # SHORT_FLAG test
  #
  
  def test_SHORT_FLAG
    r = SHORT_FLAG
    
    assert '-o' =~ r
    assert '--' =~ r
    
    # non-matching
    assert 'arg' !~ r
    assert '--long' !~ r
  end
  
  #
  # SWITCH test
  #
  
  def test_SWITCH
    r = SWITCH
    
    assert '--[no-]opt' =~ r
    assert_equal '', $1
    assert_equal 'no', $2
    assert_equal 'opt', $3
    
    assert '--nest:[no-]opt' =~ r
    assert_equal 'nest:', $1
    assert_equal 'no', $2
    assert_equal 'opt', $3
    
    # non-matching
    assert 'desc' !~ r
    assert '-' !~ r
    assert '--' !~ r
    assert '--long' !~ r
    assert '-s' !~ r
  end
  
  #
  # shortify test
  #
  
  def test_shortify_documentation
    assert_equal '-o', shortify('-o')
    assert_equal '-o', shortify(:o)
  end
  
  def test_shortify_turns_option_into_short
    assert_equal '-o', shortify('o')
    assert_equal '-a', shortify('-a')
    assert_equal '-T', shortify(:T)
  end
  
  def test_shortify_returns_nils
    assert_equal nil, shortify(nil)
  end
  
  def test_shortify_raises_error_for_invalid_short
    e = assert_raises(ArgumentError) { shortify('-long') }
    assert_equal 'invalid short flag: -long', e.message
    
    e = assert_raises(ArgumentError) { shortify('') }
    assert_equal 'invalid short flag: -', e.message
  end
  
  #
  # longify test
  #
  
  def test_longify_documentation
    assert_equal '--opt', longify('--opt')
    assert_equal '--opt', longify(:opt)
  end
  
  def test_longify_turns_option_into_long
    assert_equal '--option', longify('option')
    assert_equal '--an-option', longify('--an-option')
    assert_equal '--T', longify(:T)
  end
  
  def test_longify_returns_nils
    assert_equal nil, longify(nil)
  end
  
  def test_longify_raises_error_for_invalid_long
    e = assert_raises(ArgumentError) { longify('-l') }
    assert_equal 'invalid long flag: -l', e.message
    
    e = assert_raises(ArgumentError) { longify('') }
    assert_equal 'invalid long flag: --', e.message
  end
  
  #
  # prefix_long test
  #
  
  def test_prefix_long_documentation
    assert_equal '--no-opt', prefix_long('--opt', 'no-')
    assert_equal '--nested:no-opt', prefix_long('--nested:opt', 'no-')
  end
  
  #
  # option? test
  #
  
  def test_option_check_returns_true_if_arg_is_an_option
    assert_equal false, option?(nil)
    assert_equal false, option?('-')
    assert_equal false, option?(:'--opt')
    
    assert_equal true, option?('--') # an odd but valid short
    assert_equal true, option?('-s')
    assert_equal true, option?('--long')
    assert_equal true, option?('--no-long')
    assert_equal true, option?('--nest:long')
  end
  
  #
  # next_arg test
  #
  
  def test_next_arg_shifts_an_arg_from_argv_if_it_is_not_an_option
    args = %w{a -b c}
    assert_equal 'a', next_arg(args)
    assert_equal %w{-b c}, args
    
    assert_equal nil, next_arg(args)
    assert_equal %w{-b c}, args
  end
  
  def test_next_arg_returns_default_if_the_next_arg_is_an_option
    assert_equal 'a', next_arg(%w{-b c}, 'a')
  end
end