require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/utils'

class ConfigParser::UtilsTest < Test::Unit::TestCase
  include ConfigParser::Utils

  attr_reader :config
  
  def setup
    @config = {}
  end
  
  #
  # OPTION test
  #
  
  def test_OPTION
    r = OPTION
    
    assert '-s' =~ r
    assert_equal '-s', $1
    assert_equal '-', $2
    assert_equal nil, $3
    
    assert '--long-option' =~ r
    assert_equal '--long-option', $1
    assert_equal '--', $2
    assert_equal nil, $3
    
    assert '-s VALUE' =~ r
    assert_equal '-s', $1
    assert_equal '-', $2
    assert_equal 'VALUE', $3
    
    assert '--long-option VALUE' =~ r
    assert_equal '--long-option', $1
    assert_equal '--', $2
    assert_equal 'VALUE', $3
    
    assert '-n:s' =~ r
    assert_equal '-n:s', $1
    assert_equal '-', $2
    assert_equal nil, $3
    
    assert '--nest:long-option' =~ r
    assert_equal '--nest:long-option', $1
    assert_equal '--', $2
    assert_equal nil, $3
    
    # non-matching
    assert 'desc' !~ r
    assert '-' !~ r
    assert '--' !~ r
    assert '---' !~ r
    assert '--.' !~ r
    assert '--=VALUE' !~ r
  end
  
  #
  # SWITCH test
  #
  
  def test_SWITCH
    r = SWITCH
    
    assert '--[no-]long-option' =~ r
    assert_equal nil, $1
    assert_equal 'no', $2
    assert_equal 'long-option', $3
    assert_equal nil, $4
    
    assert '--[no-]long-option VALUE' =~ r
    assert_equal nil, $1
    assert_equal 'no', $2
    assert_equal 'long-option', $3
    assert_equal 'VALUE', $4
    
    assert '--nest:prefix:[no-]long-option' =~ r
    assert_equal 'nest:prefix', $1
    assert_equal 'no', $2
    assert_equal 'long-option', $3
    assert_equal nil, $4
    
    # non-matching
    assert 'desc' !~ r
    assert '-' !~ r
    assert '--' !~ r
    assert '---' !~ r
    assert '--.' !~ r
    assert '-[n-]s' !~ r
  end
  
  #
  # LONG_OPTION test
  #
  
  def test_LONG_OPTION
    r = LONG_OPTION
    
    assert '--long-option' =~ r
    assert_equal '--long-option', $1
    assert_equal nil, $2
    
    assert '--long-option=value' =~ r
    assert_equal '--long-option', $1
    assert_equal 'value', $2
    
    assert '--long-option=' =~ r
    assert_equal '--long-option', $1
    assert_equal '', $2
    
    assert '--nested:long-option=value' =~ r
    assert_equal '--nested:long-option', $1
    assert_equal 'value', $2
    
    assert '--long-option=value=with=equals' =~ r
    assert_equal '--long-option', $1
    assert_equal 'value=with=equals', $2
    
    # non-matching
    assert 'arg' !~ r
    assert '-o' !~ r
    assert '--' !~ r
    assert '---' !~ r
    assert '--.' !~ r
    assert '--=value' !~ r
  end
  
  #
  # SHORT_OPTION test
  #
  
  def test_SHORT_OPTION
    r = SHORT_OPTION
    
    assert '-o' =~ r
    assert_equal '-o', $1
    assert_equal nil, $2
    
    assert '-o=value' =~ r
    assert_equal '-o', $1
    assert_equal 'value', $2
    
    assert '-o=' =~ r
    assert_equal '-o', $1
    assert_equal '', $2
    
    assert '-n:l:o=value' =~ r
    assert_equal '-n:l:o', $1
    assert_equal 'value', $2
    
    assert '-o=value=with=equals' =~ r
    assert_equal '-o', $1
    assert_equal 'value=with=equals', $2
    
    # non-matching
    assert 'arg' !~ r
    assert '--o' !~ r
    assert '--' !~ r
    assert '-.' !~ r
    assert '-=value' !~ r
    assert '-n:long' !~ r
  end
  
  #
  # ALT_SHORT_OPTION test
  #
  
  def test_ALT_SHORT_OPTION
    r = ALT_SHORT_OPTION
    
    assert '-ovalue' =~ r
    assert_equal '-o', $1
    assert_equal 'value', $2
    
    assert '-n:l:ovalue' =~ r
    assert_equal '-n:l:o', $1
    assert_equal 'value', $2
    
    # non-matching
    assert 'arg' !~ r
    assert '--o' !~ r
    assert '--' !~ r
    assert '-.' !~ r
    assert '-=value' !~ r
    assert '-o' !~ r
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
    assert_equal 'invalid short option: -long', e.message
    
    e = assert_raises(ArgumentError) { shortify('') }
    assert_equal 'invalid short option: -', e.message
    
    e = assert_raises(ArgumentError) { shortify('-s=10') }
    assert_equal 'invalid short option: -s=10', e.message
  end
  
  #
  # longify test
  #
  
  def test_longify_documentation
    assert_equal '--opt', longify('--opt')
    assert_equal '--opt', longify(:opt)
    assert_equal '--opt-ion', longify(:opt_ion) 
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
    e = assert_raises(ArgumentError) { longify('-long') }
    assert_equal 'invalid long option: ---long', e.message
    
    e = assert_raises(ArgumentError) { longify('') }
    assert_equal 'invalid long option: --', e.message
    
    e = assert_raises(ArgumentError) { longify('--long=10') }
    assert_equal 'invalid long option: --long=10', e.message
  end
  
  #
  # prefix_long test
  #
  
  def test_prefix_long_documentation
    assert_equal '--no-opt', prefix_long('--opt', 'no-')
    assert_equal '--nested:no-opt', prefix_long('--nested:opt', 'no-')
  end
end