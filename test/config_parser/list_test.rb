require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/list'

class ListTest < Test::Unit::TestCase
  List = ConfigParser::List
  
  #
  # assign test
  #
  
  def test_assign_sets_default_if_key_is_set
    opt = List.new :key => 'key', :default => 'value'
    assert_equal({'key' => ['value']}, opt.assign({}))
  end
  
  def test_assign_does_nothing_if_key_is_not_set
    assert_equal({}, List.new.assign({}))
  end
  
  def test_assign_appends_values_to_array
    opt = List.new :key => 'key'
    config = {}
    
    opt.assign(config, 'a')
    opt.assign(config, 'b')
    opt.assign(config, 'c')
    
    assert_equal({'key' => ['a', 'b', 'c']}, config)
  end
  
  def test_assign_nests_value_into_config_if_nest_keys_are_set
    opt = List.new :key => 'c', :nest_keys => ['a', 'b']
    config = {}
    
    opt.assign(config, 'a')
    opt.assign(config, 'b')
    opt.assign(config, 'c')
    
    assert_equal({'a' => {'b' => {'c' => ['a', 'b', 'c']}}}, config)
  end
  
  def test_assign_ignores_nest_keys_without_key
    opt = List.new :nest_keys => ['a', 'b']
    assert_equal({}, opt.assign({}))
  end
end