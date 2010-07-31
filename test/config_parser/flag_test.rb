require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/flag'

class FlagTest < Test::Unit::TestCase
  Flag = ConfigParser::Flag
  
  #
  # initialize tests
  #
  
  def test_default_initialize
    opt = Flag.new
    assert_equal nil, opt.key
    assert_equal nil, opt.long
    assert_equal nil, opt.short
    assert_equal nil, opt.desc
    assert_equal nil, opt.callback
  end
  
  def test_initialize_formats_long_flags
    opt = Flag.new :long => 'long'
    assert_equal '--long', opt.long
  end
  
  def test_initialize_formats_short_flags
    opt = Flag.new :short => 's'
    assert_equal '-s', opt.short
  end
  
  def test_initialize_sets_long_according_to_key_if_unspecified
    opt = Flag.new :key => :long
    assert_equal :long, opt.key
    assert_equal '--long', opt.long
  end
  
  def test_initialize_sets_long_according_to_key_if_unspecified
    opt = Flag.new :key => :long
    assert_equal :long, opt.key
    assert_equal '--long', opt.long
  end
  
  def test_initialize_raises_error_for_invalid_long_flag
    err = assert_raises(ArgumentError) { Flag.new(:long => '') }
    assert_equal "invalid long flag: --", err.message
    
    err = assert_raises(ArgumentError) { Flag.new(:long => '-invalid') }
    assert_equal "invalid long flag: -invalid", err.message
  end
  
  def test_initialize_raises_error_for_invalid_short_flag
    err = assert_raises(ArgumentError) { Flag.new(:short => '') }
    assert_equal "invalid short flag: -", err.message
    
    err = assert_raises(ArgumentError) { Flag.new(:short => '-invalid') }
    assert_equal "invalid short flag: -invalid", err.message
  end
  
  #
  # flags test
  #
  
  def test_flags_returns_long_and_short_flags_if_set
    opt = Flag.new :long => '--long', :short => '-s'
    assert_equal ['--long', '-s'], opt.flags
    
    opt = Flag.new :long => '--long'
    assert_equal ['--long'], opt.flags
    
    opt = Flag.new
    assert_equal [], opt.flags
  end
  
  #
  # parse test
  #
  
  def test_parse_returns_true
    assert_equal true, Flag.new.parse('--flag', nil)
  end
  
  def test_parse_returns_callback_result_if_provided
    opt = Flag.new { 'value' }
    assert_equal 'value', opt.parse('--flag', nil)
  end
  
  def test_parse_raises_error_if_value_is_provided
    opt = Flag.new
    
    e = assert_raises(RuntimeError) { opt.parse('--flag', 'value') }
    assert_equal "value specified for flag: --flag", e.message
  end
  
  #
  # assign test
  #
  
  def test_assign_sets_default_to_config_if_key_is_set
    opt = Flag.new :key => 'key', :default => 'value'
    assert_equal({'key' => 'value'}, opt.assign({}))
  end
  
  def test_assign_sets_value_if_specified
    opt = Flag.new :key => 'key', :default => 'value'
    assert_equal({'key' => 'VALUE'}, opt.assign({}, 'VALUE'))
  end
  
  def test_assign_will_assign_nil
    opt = Flag.new :key => 'key'
    assert_equal({'key' => nil}, opt.assign({}))
  end
  
  def test_assign_does_nothings_if_key_is_not_set
    assert_equal({}, Flag.new.assign({}))
  end
  
  def test_assign_nests_value_into_config_if_nest_keys_are_set
    opt = Flag.new :key => 'c', :nest_keys => ['a', 'b']
    assert_equal({'a' => {'b' => {'c' => nil}}}, opt.assign({}))
  end
  
  def test_assign_ignores_nest_keys_without_key
    opt = Flag.new :nest_keys => ['a', 'b']
    assert_equal({}, opt.assign({}))
  end
end