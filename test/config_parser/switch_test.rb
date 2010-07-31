require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/switch'

class SwitchTest < Test::Unit::TestCase
  Switch = ConfigParser::Switch
  
  attr_reader :opt
  
  def setup
    @opt = Switch.new(:long => 'switch')
  end
  
  #
  # parse test
  #
  
  def test_parse_raises_error_if_value_is_provided
    e = assert_raises(RuntimeError) { opt.parse('--switch', 'value') }
    assert_equal "value specified for switch: --switch", e.message
  end
  
  #
  # to_s test
  #
  
  def test_to_s_adds_prefix_to_long
    opt = Switch.new(:long => 'long', :short => 's', :prefix => 'off', :desc => "description of key")
    expected = %q{
    -s, --[off-]long                 description of key                         }
    assert_equal expected, "\n#{opt.to_s}"
  end
end