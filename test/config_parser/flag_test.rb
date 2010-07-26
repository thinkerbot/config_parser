require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/flag'

class FlagTest < Test::Unit::TestCase
  Flag = ConfigParser::Flag
  
  #
  # initialize tests
  #
  
  def test_default_initialize
    flag = Flag.new
    assert_equal nil, flag.key
    assert_equal nil, flag.long
    assert_equal nil, flag.short
    assert_equal nil, flag.desc
    assert_equal nil, flag.callback
  end
  
  def test_initialize_formats_long_flags
    flag = Flag.new :long => 'long'
    assert_equal '--long', flag.long
  end
  
  def test_initialize_formats_short_flags
    flag = Flag.new :short => 's'
    assert_equal '-s', flag.short
  end
  
  def test_initialize_sets_long_according_to_key_if_unspecified
    flag = Flag.new :key => :long
    assert_equal :long, flag.key
    assert_equal '--long', flag.long
  end
  
  def test_initialize_sets_long_according_to_key_if_unspecified
    flag = Flag.new :key => :long
    assert_equal :long, flag.key
    assert_equal '--long', flag.long
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
    flag = Flag.new :long => '--long', :short => '-s'
    assert_equal ['--long', '-s'], flag.flags
    
    flag = Flag.new :long => '--long'
    assert_equal ['--long'], flag.flags
    
    flag = Flag.new
    assert_equal [], flag.flags
  end
end