require File.expand_path('../../test_helper', __FILE__)
require 'config_parser/list'

class ListTest < Test::Unit::TestCase
  List = ConfigParser::List
  
  #
  # assign test
  #
  
  def test_assign_returns_empty_hash_if_key_is_not_set
    assert_equal({}, List.new.assign('value'))
  end
  
  def test_assign_appends_value_to_array_if_key_is_set
    list = List.new :key => 'key'
    config = {}
    
    list.assign('a', config)
    list.assign('b', config)
    list.assign('c', config)
    
    assert_equal({'key' => ['a', 'b', 'c']}, config)
  end
end