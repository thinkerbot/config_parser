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
  
  def test_parse_returns_true
    assert_equal true, opt.parse('--switch')
  end
  
  def test_parse_returns_false_for_nolong
    assert_equal false, opt.parse('--no-switch')
  end
  
  def test_parse_returns_callback_result_if_provided
    opt = Switch.new(:long => 'switch') {|value| "got: #{value}" }
    assert_equal 'got: true', opt.parse('--switch')
  end
  
  def test_parse_raises_error_if_value_is_provided
    e = assert_raises(RuntimeError) { opt.parse('--switch', 'value') }
    assert_equal "value specified for switch: --switch", e.message
  end
end