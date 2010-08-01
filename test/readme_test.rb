require File.expand_path('../test_helper', __FILE__)
require 'config_parser'

class ReadmeTest < Test::Unit::TestCase
  def test_documentation
    parser = ConfigParser.new
    parser.on '-s', '--long LONG', 'a standard option' do |value|
      parser[:long] = value
    end

    parser.on '--[no-]switch', 'a switch' do |value|
      parser[:switch] = value
    end

    parser.on '--flag', 'a flag' do
      parser[:flag] = true
    end

    expected = ['a', 'b', 'c']
    assert_equal expected, parser.parse('a b --long arg --switch --flag c')

    expected = {:long => 'arg', :switch => true, :flag => true}
    assert_equal expected, parser.config

    expected = %q{
    -s, --long LONG                  a standard option
        --[no-]switch                a switch
        --flag                       a flag
}
    assert_equal expected, "\n" + parser.to_s

    #

    parser = ConfigParser.new
    parser.add(:key, 'default')

    assert_equal ['a', 'b', 'c'], parser.parse('a b --key option c')
    assert_equal({:key => 'option'}, parser.config)

    assert_equal ['a', 'b', 'c'], parser.parse('a b c')
    assert_equal({:key => 'default'}, parser.config)

    #

    parser = ConfigParser.new
    parser.add(:x, nil, '-o', '--one', 'by args') {|value| value.upcase }
    parser.add(:y, false, :long => 'two', :desc => 'by hash')

    expected = ['a', 'b', 'c']
    assert_equal(expected, parser.parse('a b --one value --two c'))

    expected = {:x => 'VALUE', :y => true}
    assert_equal(expected, parser.config)
  end
end