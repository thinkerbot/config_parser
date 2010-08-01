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
    parser.add :flag, false   
    parser.add :switch, true  
    parser.add :list, []      
    parser.add :opt, 'default'

    assert_equal ['a', 'b', 'c'], parser.parse('a b c')
    
    expected = {
      :flag   => false,
      :switch => true,
      :list   => [],
      :opt    => 'default'
    }
    assert_equal expected, parser.config

    args = %w{a b --flag --no-switch --list one --list two,three --opt value c}
    assert_equal ['a', 'b', 'c'], parser.parse(args)
    
    expected = {
      :flag   => true,
      :switch => false,
      :list   => ['one', 'two', 'three'],
      :opt    => 'value'
    }
    assert_equal expected, parser.config

    #

    parser = ConfigParser.new
    parser.add(:x, nil, '--one', 'by args') {|value| value.upcase }
    parser.add(:y, nil, :long => 'two', :desc => 'by hash')

    expected = ['a', 'b', 'c']
    assert_equal(expected, parser.parse('a b --one value --two value c'))

    expected = {:x => 'VALUE', :y => 'value'}
    assert_equal(expected, parser.config)
  end
end