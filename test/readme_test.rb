require File.expand_path('../test_helper', __FILE__)
require 'config_parser'

class ReadmeTest < Test::Unit::TestCase
  def test_documentation
    parser = ConfigParser.new
    parser.on '--option OPTION', 'a standard option' do |value|
      parser[:option] = value
    end

    parser.on '--[no-]switch', 'a switch' do |value|
      parser[:switch] = value
    end

    parser.on '--flag', 'a flag' do
      parser[:flag] = true
    end

    expected = ['a', 'b', 'c']
    assert_equal expected, parser.parse('a b --flag --switch --option value c')

    expected = {
      :option => 'value',
      :switch => true,
      :flag   => true
    }
    assert_equal expected, parser.config

    expected = %q{
        --option OPTION              a standard option
        --[no-]switch                a switch
        --flag                       a flag
}
    assert_equal expected, "\n" + parser.to_s

    #

    parser = ConfigParser.new
    parser.add :option, 'default'      # regular option with a default value
    parser.add :switch, true           # true makes a --[no-]switch
    parser.add :flag, false            # false as a default makes a --flag
    parser.add :list, []               # an array makes a list-style option

    expected = ['a', 'b', 'c']
    assert_equal expected, parser.parse('a b --flag --list x --list y,z c')

    expected = {
      :option => 'default',
      :switch => true,
      :flag   => true,
      :list   => ['x', 'y', 'z']
    }
    assert_equal expected, parser.config
    
    #

    parser = ConfigParser.new

    # use args to define the option
    parser.add(:x, nil, '-o', '--one')

    # use an options hash to define the option
    parser.add(:y, nil, :short => 't', :long => 'two')

    # use a block to process the values
    parser.add(:z, nil, :long => 'three') {|value| value.upcase }

    expected = ['a', 'b', 'c']
    assert_equal(expected, parser.parse('a b --one uno --two dos --three tres c'))

    expected = {:x => 'uno', :y => 'dos', :z => 'TRES'}
    assert_equal(expected, parser.config)
  end
end