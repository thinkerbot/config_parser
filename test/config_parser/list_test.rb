require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/list'

class ListTest < Test::Unit::TestCase
  List = ConfigParser::List
  
  attr_reader :opt
  
  def setup
    @opt = List.new
  end
  
  #
  # process test
  #
  
  def test_process_splits_string_values_along_delimiter
    assert_equal ['a', 'b', 'c'], opt.process('a,b,c')
  end
  
  def test_process_returns_array_values_directly
    assert_equal [1,2,3], opt.process([1,2,3])
  end
  
  def test_process_passes_each_arg_to_the_block_for_processing
    opt = List.new(:callback => lambda {|arg| Integer(arg) })
    assert_equal [1,2,3], opt.process('1,2,3')
  end
  
  #
  # assign test
  #
  
  def test_assign_sets_values_if_key_is_set
    opt = List.new :key => 'key'
    assert_equal({'key' => ['value']}, opt.assign({}, ['value']))
  end
  
  def test_assign_does_nothing_if_key_is_not_set
    assert_equal({}, opt.assign({}, ['value']))
  end
  
  def test_multiple_assigns_append_new_values_to_existing
    opt = List.new :key => 'key'
    config = {}
    
    opt.assign(config, ['a'])
    opt.assign(config, ['b'])
    opt.assign(config, ['c'])
    
    assert_equal({'key' => ['a', 'b', 'c']}, config)
  end
  
  def test_assign_overwrites_existing_values_after_reset
    opt = List.new :key => 'key'
    config = {'key' => ['a', 'b', 'c']}
    
    opt.reset
    opt.assign(config, ['x'])
    opt.assign(config, ['y'])
    opt.assign(config, ['z'])
    
    assert_equal({'key' => ['x', 'y', 'z']}, config)
  end
  
  def test_assign_nests_value_into_config_if_nest_keys_are_set
    opt = List.new :key => 'c', :nest_keys => ['a', 'b']
    config = {}
    
    opt.assign(config, ['a'])
    opt.assign(config, ['b'])
    opt.assign(config, ['c'])
    
    assert_equal({'a' => {'b' => {'c' => ['a', 'b', 'c']}}}, config)
  end
  
  def test_assign_ignores_nest_keys_without_key
    opt = List.new :nest_keys => ['a', 'b']
    assert_equal({}, opt.assign({}, ['value']))
  end
end