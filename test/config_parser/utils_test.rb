require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/utils'

class ConfigParser::UtilsTest < Test::Unit::TestCase
  include ConfigParser::Utils

  attr_reader :config
  
  def setup
    @config = {}
  end
  
  #
  # LONG_OPTION test
  #
  
  def test_LONG_OPTION
    r = LONG_OPTION
    
    assert "--long-option" =~ r
    assert_equal "--long-option", $1
    assert_equal nil, $2
    
    assert "--long-option=value" =~ r
    assert_equal "--long-option", $1
    assert_equal "value", $2
    
    assert "--long-option=" =~ r
    assert_equal "--long-option", $1
    assert_equal "", $2
    
    assert "--nested:long-option=value" =~ r
    assert_equal "--nested:long-option", $1
    assert_equal "value", $2
    
    assert "--long-option=value=with=equals" =~ r
    assert_equal "--long-option", $1
    assert_equal "value=with=equals", $2
    
    # non-matching
    assert "arg" !~ r
    assert "-o" !~ r
    assert "--" !~ r
    assert "---" !~ r
    assert "--." !~ r
    assert "--1" !~ r
    assert "--=value" !~ r
  end
  
  #
  # SHORT_OPTION test
  #
  
  def test_SHORT_OPTION
    r = SHORT_OPTION
    
    assert "-o" =~ r
    assert_equal "-o", $1
    assert_equal nil, $2
    
    assert "-o=value" =~ r
    assert_equal "-o", $1
    assert_equal "value", $2
    
    assert "-o=" =~ r
    assert_equal "-o", $1
    assert_equal "", $2
    
    assert "-n:l:o=value" =~ r
    assert_equal "-n:l:o", $1
    assert_equal "value", $2
    
    assert "-o=value=with=equals" =~ r
    assert_equal "-o", $1
    assert_equal "value=with=equals", $2
    
    # non-matching
    assert "arg" !~ r
    assert "--o" !~ r
    assert "--" !~ r
    assert "-." !~ r
    assert "-1" !~ r
    assert "-=value" !~ r
    assert "-n:long" !~ r
  end
  
  #
  # ALT_SHORT_OPTION test
  #
  
  def test_ALT_SHORT_OPTION
    r = ALT_SHORT_OPTION
    
    assert "-ovalue" =~ r
    assert_equal "-o", $1
    assert_equal "value", $2

    assert "-n:l:ovalue" =~ r
    assert_equal "-n:l:o", $1
    assert_equal "value", $2
    
    # non-matching
    assert "arg" !~ r
    assert "--o" !~ r
    assert "--" !~ r
    assert "-." !~ r
    assert "-1" !~ r
    assert "-=value" !~ r
    assert "-o" !~ r
  end
  
  #
  # shortify test
  #
  
  def test_shortify_documentation
    assert_equal '-o', shortify("-o")
    assert_equal '-o', shortify(:o)
  end
  
  def test_shortify_turns_option_into_short
    assert_equal "-o", shortify("o")
    assert_equal "-a", shortify("-a")
    assert_equal "-T", shortify(:T)
  end
  
  def test_shortify_returns_nils
    assert_equal nil, shortify(nil)
  end
  
  def test_shortify_raises_error_for_invalid_short
    e = assert_raises(ArgumentError) { shortify("-long") }
    assert_equal "invalid short option: -long", e.message
    
    e = assert_raises(ArgumentError) { shortify("-1") }
    assert_equal "invalid short option: -1", e.message
    
    e = assert_raises(ArgumentError) { shortify("") }
    assert_equal "invalid short option: -", e.message
    
    e = assert_raises(ArgumentError) { shortify("-s=10") }
    assert_equal "invalid short option: -s=10", e.message
  end
  
  #
  # longify test
  #
  
  def test_longify_documentation
    assert_equal '--opt', longify("--opt")
    assert_equal '--opt', longify(:opt)
    assert_equal '--opt-ion', longify(:opt_ion) 
  end
  
  def test_longify_turns_option_into_long
    assert_equal "--option", longify("option")
    assert_equal "--an-option", longify("--an-option")
    assert_equal "--T", longify(:T)
  end
  
  def test_longify_returns_nils
    assert_equal nil, longify(nil)
  end
  
  def test_longify_raises_error_for_invalid_long
    e = assert_raises(ArgumentError) { longify("-long") }
    assert_equal "invalid long option: ---long", e.message
    
    e = assert_raises(ArgumentError) { longify("1") }
    assert_equal "invalid long option: --1", e.message
    
    e = assert_raises(ArgumentError) { longify("") }
    assert_equal "invalid long option: --", e.message
    
    e = assert_raises(ArgumentError) { longify("--long=10") }
    assert_equal "invalid long option: --long=10", e.message
  end
  
  #
  # prefix_long test
  #
  
  def test_prefix_long_documentation
    assert_equal '--no-opt', prefix_long("--opt", 'no-')
    assert_equal '--nested:no-opt', prefix_long("--nested:opt", 'no-')
  end
  
  #
  # infer_long test
  #
  
  def test_infer_long_documentation
    assert_equal({:long => '--key'}, infer_long(:key, {}))
  end
  
  #
  # infer_arg_name test
  #
  
  def test_infer_arg_name_documentation
    assert_equal({:long => '--opt', :arg_name => 'OPT'}, infer_arg_name(:key, {:long => '--opt'}))
    assert_equal({:arg_name => 'KEY'}, infer_arg_name(:key, {}))
  end
  
  def test_infer_arg_name_does_not_infer_argname_if_nil
    assert_equal({:arg_name => nil}, infer_arg_name(:key, {:arg_name => nil}))
  end
end