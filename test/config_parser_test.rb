require File.expand_path('../test_helper', __FILE__)
require 'config_parser'

class ConfigParserTest < Test::Unit::TestCase
  Option = ConfigParser::Option
  
  attr_reader :c
  
  def setup
    @c = ConfigParser.new
  end
  
  #
  # initialize test
  #
  
  def test_initialize
    c = ConfigParser.new
    assert_equal({}, c.options)
    assert_equal({}, c.config)
  end
  
  def test_initialize_sets_config
    config = {}
    c = ConfigParser.new(config)
    assert_equal config.object_id, c.config.object_id
  end
  
  #
  # AGET test
  #
  
  def test_AGET_gets_config_value
    assert_equal(nil, c[:key])
    c.config[:key] = 'value'
    assert_equal('value', c[:key])
  end
  
  #
  # ASET test
  #
  
  def test_ASET_sets_config_value
    assert_equal({}, c.config)
    c[:key] = 'value'
    assert_equal({:key => 'value'}, c.config)
  end
  
  #
  # register test
  #
  
  def test_register_adds_opt_to_registry
    opt = Option.new
    c.register(opt)
    
    assert_equal [opt], c.registry
  end
  
  def test_register_adds_opt_to_options_by_switches
    opt = Option.new(:long => 'long', :short => 's')
    c.register(opt)
    
    assert_equal({'--long' => opt, '-s' => opt}, c.options)
  end
  
  def test_register_raises_error_for_conflicting_switches
    c.register(Option.new(:long => 'key', :short => 'k'))
    
    e = assert_raises(ArgumentError) { c.register(Option.new(:long => 'key')) }
    assert_equal 'already mapped to a different option: --key', e.message
    
    e = assert_raises(ArgumentError) { c.register(Option.new(:short => 'k')) }
    assert_equal 'already mapped to a different option: -k', e.message
  end
  
  def test_register_removes_conflicting_options_on_override
    o1 = Option.new(:long => 'one')
    o2 = Option.new(:short => 'a')
    o3 = Option.new(:long => 'two', :short => 'b')
    
    c.register(o1)
    c.register(o2)
    c.register(o3)
        
    assert_equal [o1, o2, o3], c.registry
    assert_equal({
      '--one' => o1,
      '-a'    => o2,
      '--two' => o3,
      '-b'    => o3
    }, c.options)
    
    o4 = Option.new(:long => 'one', :short => 'a')
    c.register(o4, true)
    
    assert_equal [o3, o4], c.registry
    assert_equal({
      '--one' => o4,
      '-a'    => o4,
      '--two' => o3,
      '-b'    => o3
    }, c.options)
  end
  
  def test_register_ignores_options_that_have_already_been_registered
    opt = Option.new(:long => 'key', :short => 'k')
    c.register(opt)
    c.register(opt)
  end
  
  #
  # unregister
  #
  
  def test_unregister_removes_opt_from_registry_and_options
    opt = Option.new(:long => 'key', :short => 'k')
    c.register(opt)
    
    assert_equal [opt], c.registry
    assert_equal({'--key' => opt, '-k' => opt}, c.options)
    
    c.unregister(opt)
    
    assert_equal [], c.registry
    assert_equal({}, c.options)
  end
  
  #
  # sort_opts!
  #
  
  def test_sort_opts_sorts_options_in_the_registry_in_groups_defined_by_separators
   z = c.register Option.new(:long => 'zzz')
   x = c.register Option.new(:long => 'xxx')
   y = c.register Option.new(:long => 'yyy')
   
   c.separator ''
   
   p = c.register Option.new(:short => 'p')
   r = c.register Option.new(:short => 'r')
   q = c.register Option.new(:short => 'q')
   
   c.sort_opts!
   assert_equal [x, y, z, '', p, q, r], c.registry
  end
  
  #
  # on test
  #
  
  def test_on_adds_and_returns_option
    opt = c.on
    assert_equal [opt], c.registry
  end
  
  def test_on_sets_callback_in_option
    callback = lambda {}
    opt = c.on(&callback)
    assert_equal callback, opt.callback
  end
  
  def test_on_uses_a_trailing_hash_for_attrs
    opt = c.on('-s', :long => 'long')
    assert_equal '-s', opt.short
    assert_equal '--long', opt.long
  end
  
  def test_on_parses_option_attributes
    opt = c.on('-s', '--long ARGNAME', 'option description')
    assert_equal '-s', opt.short
    assert_equal '--long', opt.long
    assert_equal 'ARGNAME', opt.arg_name
    assert_equal 'option description', opt.desc
  end
  
  def test_on_parses_optional_argname
    opt = c.on('--mandatory ARGNAME')
    assert_equal false, opt.optional
    
    opt = c.on('--required [ARGNAME]')
    assert_equal true, opt.optional
  end
  
  def test_on_parses_nested_long_option
    opt = c.on('--nest:long')
    assert_equal ['nest'], opt.nest_keys
    assert_equal '--nest:long', opt.long
  end
  
  def test_on_creates_option_for_long_options_with_arg_name
    opt = c.on('--long ARGNAME')
    assert_equal ConfigParser::Option, opt.class
  end
  
  def test_on_creates_option_for_short_options_with_arg_name
    opt = c.on('-s ARGNAME')
    assert_equal ConfigParser::Option, opt.class
  end
  
  def test_on_creates_option_for_manually_specified_argname
    opt = c.on(:arg_name => 'ARGNAME')
    assert_equal ConfigParser::Option, opt.class
  end
  
  def test_on_creates_list_for_argname_with_commas
    opt = c.on(:arg_name => 'A,B,C')
    assert_equal ConfigParser::List, opt.class
  end
  
  def test_on_creates_flag_option_for_options_without_arg_name
    opt = c.on('--long')
    assert_equal ConfigParser::Flag, opt.class
  end
  
  def test_on_creates_switch_option_with_switch
    opt = c.on('--[no-]switch')
    assert_equal ConfigParser::Switch, opt.class
  end
  
  def test_on_allows_manual_specification_of_type
    opt = c.on('--[no-]switch', '-s ARGNAME', :option_type => :list)
    assert_equal ConfigParser::List, opt.class
  end
  
  def test_on_allows_manual_specification_of_callback
    callback = lambda {}
    opt = c.on(:callback => callback)
    assert_equal callback, opt.callback
  end
  
  def test_attrs_override_args
    opt = c.on('--a:b', :nest_keys => ['c'])
    assert_equal ['c'], opt.nest_keys
  end
  
  def test_block_overrides_callback_in_attrs
    callback = lambda {}
    overridden = lambda {}
    
    opt = c.on(:callback => overridden, &callback)
    assert_equal callback, opt.callback
  end
  
  def test_on_raises_error_when_arg_name_is_specified_for_switch
    err = assert_raises(ArgumentError) { c.on('--[no-]opt VALUE') }
    assert_equal 'arg_name specified for switch: VALUE', err.message
  end
  
  #
  # on! test
  #
  
  def test_on_bang_overrides_conflicting_options
    o1 = c.on! '--one'
    o2 = c.on! '-a'
    o3 = c.on! '-b', '--two'
    
    assert_equal [o1, o2, o3], c.registry
    assert_equal({
      '--one' => o1,
      '-a'    => o2,
      '--two' => o3,
      '-b'    => o3
    }, c.options)
    
    o4 = c.on! '-a', '--one'
    
    assert_equal [o3, o4], c.registry
    assert_equal({
      '--one' => o4,
      '-a'    => o4,
      '--two' => o3,
      '-b'    => o3
    }, c.options)
  end
  
  #
  # add test
  #
  
  def test_add_documentation
    psr = ConfigParser.new
    psr.add(:one, 'default')
    psr.add(:two, 'default', :long => '--long', :short => '-s')
  
    psr.parse("--one one --long two")
    assert_equal({:one => 'one', :two => 'two'}, psr.config)
  
    psr = ConfigParser.new
    psr.add(:flag, false, :option_type => :flag)
    psr.add(:switch, true, :option_type => :switch)
    psr.add(:list, [], :option_type => :list)
  
    psr.parse("--flag --switch --list one --list two --list three")
    assert_equal({:flag => true, :switch => true, :list => ['one', 'two', 'three']}, psr.config)
  
    psr = ConfigParser.new
    psr.add(:opt, 'default') {|input| input.reverse }
  
    psr.parse("--opt value")
    assert_equal({:opt => 'eulav'}, psr.config)
  end
  
  def test_add_adds_and_returns_an_option
    opt = c.add(:key)
    assert_equal [opt], c.registry
  end
  
  def test_add_sets_key_and_default
    opt = c.add(:key, 'value')
    
    assert_equal :key, opt.key
    assert_equal 'value', opt.default
  end
  
  def test_add_accepts_an_attributes_hash
    opt = c.add(:key, 'value', :long => 'long', :short => 's')
    
    assert_equal '--long', opt.long
    assert_equal '-s', opt.short
  end
  
  def test_add_parses_args_like_on
    opt = c.add(:key, 'value', '--long', '-s', :option_type => :list)
    assert_equal '--long', opt.long
    assert_equal '-s', opt.short
    assert_equal ConfigParser::List, opt.class
  end
  
  def test_add_defaults_to_option_type
    opt = c.add(:key, 'value')
    assert_equal ConfigParser::Option, opt.class
  end
  
  def test_add_with_array_default_defaults_to_list_type
    opt = c.add(:key, [])
    assert_equal ConfigParser::List, opt.class
  end
  
  #
  # rm test
  #
  
  def test_rm_unregisters_option_with_specified_key
    x = c.add(:x)
    y = c.add(:y)
    z = c.add(:z)
    
    assert_equal [x, y, z], c.registry
    assert_equal [x, y, z], c.options.values.sort_by {|opt| opt.key.to_s }
    
    c.rm(:y)
    
    assert_equal [x, z], c.registry
    assert_equal [x, z], c.options.values.sort_by {|opt| opt.key.to_s }
  end
  
  #
  # parse test
  #
  
  def test_parse_for_flag_yields_to_block
    was_in_block = false
    c.on('--flag') { was_in_block = true }
    
    args = c.parse %w{a --flag b}
    
    assert_equal true, was_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_for_option_yields_value_to_block
    value_in_block = nil
    c.on('--opt VALUE') {|value| value_in_block = value }
    
    args = c.parse %w{a --opt value b}
    
    assert_equal 'value', value_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_parses_equals_syntax
    value_in_block = nil
    c.on('--opt VALUE') {|value| value_in_block = value }
    
    args = c.parse %w{a --opt=value b}
    
    assert_equal 'value', value_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_with_empty_equals_syntax
    value_in_block = nil
    c.on('--opt VALUE') {|value| value_in_block = value}
    
    args = c.parse %w{a --opt= b}
    
    assert_equal '', value_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_with_short_syntax
    value_in_block = nil
    c.on('-o VALUE') {|value| value_in_block = value}
    
    args = c.parse %w{a -o value b}
    
    assert_equal 'value', value_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_with_short_equal_syntax
    value_in_block = nil
    c.on('-o VALUE') {|value| value_in_block = value}
    
    args = c.parse %w{a -o=value b}

    assert_equal 'value', value_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_with_short_empty_equals_syntax
    value_in_block = nil
    c.on('-o VALUE') {|value| value_in_block = value}
    
    args = c.parse %w{a -o= b}
    
    assert_equal '', value_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_with_compact_short_syntax
    value_in_block = nil
    c.on('-o VALUE') {|value| value_in_block = value}
    
    args = c.parse %w{a -ovalue b}
    
    assert_equal 'value', value_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_with_compact_short_syntax_picks_up_sequential_shorts
    values = {}
    c.on('-x') { values[:x] = true }
    c.on('-y') { values[:y] = true }
    
    args = c.parse %w{a -xy b}
    
    assert_equal({:x => true, :y => true}, values)
    assert_equal %w{a b}, args
  end
  
  def test_parse_with_compact_short_syntax_gives_remainder_to_first_opt_taking_a_value
    values = {}
    c.on('-x VALUE') {|value| values[:x] = value }
    c.on('-y') { values[:y] = true }
    
    args = c.parse %w{a -xyz b}
    
    assert_equal({:x => 'yz'}, values)
    assert_equal %w{a b}, args
    
    values.clear
    args = c.parse %w{a -yxz b}
    
    assert_equal({:x => 'z', :y => true}, values)
    assert_equal %w{a b}, args
  end
  
  def test_parse_raises_error_if_no_value_is_available
    c.on('--opt VALUE')
    err = assert_raises(RuntimeError) { c.parse %w{--opt} }
    assert_equal 'no value provided for: --opt', err.message
  end
  
  def test_parse_uses_default_if_no_value_is_available_and_value_is_optional
    c.add(:one, 1, :optional => true)
    c.add(:two, 2, :optional => true)
    
    args = c.parse %w{a --one --two 2 b}
    assert_equal({:one => 1, :two => '2'}, c.config)
    assert_equal %w{a b}, args
    
    args = c.parse %w{a b --one}
    assert_equal({:one => 1, :two => 2}, c.config)
    assert_equal %w{a b}, args
  end
  
  def test_parse_stops_parsing_on_option_break
    values = {}
    c.on('--one VALUE') {|value| values[:one] = value }
    c.on('--two VALUE') {|value| values[:two] = value }
    
    args = c.parse %w{a --one 1 -- --two 2}
    
    assert_equal({:one => '1'}, values)
    assert_equal %w{a --two 2}, args
  end
  
  def test_parse_preserves_option_break_if_specified
    c.preserve_option_break = true
    args = c.parse %w{a -- b}
    assert_equal %w{a -- b}, args
  end
  
  def test_parse_can_configure_option_break
    c.on('--opt')
    
    c.option_break = '---'
    args = c.parse %w{a --- --opt b}
    assert_equal %w{a --opt b}, args
  end
  
  def test_parse_compares_option_break_using_case_equality
    c.on('--opt')
    
    c.option_break = /-{3}/
    args = c.parse %w{a --- --opt b}
    assert_equal %w{a --opt b}, args
  end
  
  def test_parse_handles_non_string_inputs
    value_in_block = nil
    c.on('--opt VALUE') {|value| value_in_block = value}
    
    o = Object.new
    args = c.parse([o, 1, {}, '--opt', :sym, []])
    
    assert_equal(:sym, value_in_block)
    assert_equal([o, 1, {},[]], args)
  end
  
  def test_parse_does_not_modify_argv
    c.on('--opt VALUE')
    
    argv = %w{a --opt=value b}
    args = c.parse(argv)
    
    assert_equal %w{a --opt=value b}, argv
    assert_equal %w{a b}, args
  end

  def test_parse_splits_string_argvs_using_Shellwords
    value_in_block = nil
    c.on('--opt VALUE') {|value| value_in_block = value}
    
    args = c.parse('a --opt value b')
    
    assert_equal 'value', value_in_block
    assert_equal %w{a b}, args
  end
  
  def test_parse_sets_config_values
    c.add(:key, 'default')
    args = c.parse %w{a --key value b}
    
    assert_equal({:key => 'value'}, c.config)
    assert_equal %w{a b}, args
  end
  
  def test_parse_assigns_default_config_values
    c.add(:key, 'default')
    c.parse %w{a b}
    
    assert_equal({:key => 'default'}, c.config)
  end
  
  def test_parse_does_not_assign_default_config_values_unless_specified
    c.add(:key, 'default')
    
    c.assign_defaults = false
    c.parse %w{a b}
    
    assert_equal({}, c.config)
  end
  
  def test_parse_raises_error_for_unknown_option
    err = assert_raises(RuntimeError) { c.parse %w{--unknown option} }
    assert_equal "unknown option: --unknown", err.message
    
    err = assert_raises(RuntimeError) { c.parse %w{--unknown option} }
    assert_equal "unknown option: --unknown", err.message
    
    err = assert_raises(RuntimeError) { c.parse %w{--unknown} }
    assert_equal "unknown option: --unknown", err.message
  end

  #
  # parse! test
  #
  
  def test_parse_bang_removes_parsed_args_from_argv
    c.on('--opt VALUE')
    
    argv = %w{a --opt=value b}
    c.parse!(argv)
    
    assert_equal %w{a b}, argv
  end
  
  def test_parse_bang_splits_string_argvs_using_Shellwords
    value_in_block = nil
    c.on('--opt VALUE') {|value| value_in_block = value}
    
    args = c.parse!("a --opt value b")
    
    assert_equal 'value', value_in_block
    assert_equal %w{a b}, args
  end
  
  #
  # parse flag test
  #
  
  def test_parse_flag_sets_negative_default_in_config
    c.add(:key, false, :option_type => :flag)

    c.parse %w{a b c}
    assert_equal({:key => false}, c.config)
    
    c.parse %w{a --key c}
    assert_equal({:key => true}, c.config)
  end
  
  def test_parse_nests_as_specified
    c.add(:c, false, :long => 'key', :nest_keys => [:a, :b], :option_type => :flag)
    
    c.parse %w{a --key c}
    assert_equal({:a => {:b => {:c => true}}}, c.config)
  end
  
  def test_parse_flag_calls_callback
    was_in_block = nil
    c.on('--opt') { was_in_block = true }

    c.parse %w{a --opt b}
    assert was_in_block
  end
  
  def test_parse_flag_does_not_call_callback_unless_specified
    was_in_block = nil
    c.on('--opt') { was_in_block = true }

    c.parse %w{a b}
    assert_equal nil, was_in_block
  end
  
  def test_parse_flag_raises_error_if_value_is_specified
    value_in_block = nil
    c.on('--opt') {|value| value_in_block = value}
   
    err = assert_raises(RuntimeError) { c.parse %w{a --opt=value b} }
    assert_equal 'value specified for --opt: "value"', err.message
  end
  
  #
  # parse switch test
  #
  
  def test_parse_switch_sets_default_in_config
    c.add(:key, true, :option_type => :switch)

    c.parse %w{a b c}
    assert_equal({:key => true}, c.config)
    
    c.parse %w{a --key c}
    assert_equal({:key => true}, c.config)
    
    c.parse %w{a --no-key c}
    assert_equal({:key => false}, c.config)
  end
  
  def test_parse_switch_passes_true_to_callback
    value_in_block = nil
    c.on('--[no-]opt') {|value| value_in_block = value}

    c.parse %w{a --opt b}
    assert_equal true, value_in_block
  end
  
  def test_parse_switch_passes_true_for_short
    value_in_block = nil
    c.on('--[no-]opt', '-o') {|value| value_in_block = value}

    c.parse %w{a -o b}
    assert_equal true, value_in_block
  end
  
  def test_parse_switch_passes_false_for_no_switch
    value_in_block = nil
    c.on('--[no-]opt') {|value| value_in_block = value}
   
    c.parse %w{a --no-opt b}
    assert_equal false, value_in_block
  end
  
  def test_parse_switch_does_not_call_block_without_switch
    was_in_block = nil
    c.on('--[no-]opt') { was_in_block = true }

    c.parse %w{a b}
    assert_equal nil, was_in_block
  end
  
  def test_parse_switch_raises_error_if_value_is_specified
    value_in_block = nil
    c.on('--[no-]opt') {|value| value_in_block = value}
   
    err = assert_raises(RuntimeError) { c.parse %w{a --opt=value b} }
    assert_equal 'value specified for --opt: "value"', err.message
    
    err = assert_raises(RuntimeError) { c.parse %w{a --no-opt=value b} }
    assert_equal 'value specified for --no-opt: "value"', err.message
  end
  
  #
  # parse list test
  #
  
  def test_parse_list
    c.add(:opt, [])
    args = c.parse %w{a --opt one --opt two --opt three b}
    
    assert_equal({:opt => ['one', 'two', 'three']}, c.config)
    assert_equal %w{a b}, args
  end
  
  def test_parse_list_assigns_defaults
    c.add(:opt, ['x', 'y', 'z'])
    args = c.parse %w{a b}
    
    assert_equal({:opt => ['x', 'y', 'z']}, c.config)
    assert_equal %w{a b}, args
  end
  
  def test_parse_list_overrides_defaults
    c.add(:opt, ['x', 'y', 'z'])
    args = c.parse %w{a --opt one --opt two --opt three b}
    
    assert_equal({:opt => ['one', 'two', 'three']}, c.config)
    assert_equal %w{a b}, args
  end
  
  def test_parse_list_splits_multivalues
    c.add(:opt, [])
    args = c.parse %w{a --opt one --opt two,three b}
    
    assert_equal({:opt => ['one', 'two', 'three']}, c.config)
    assert_equal %w{a b}, args
  end
  
  #
  # to_s test
  #
  
  def test_to_s
    c.on('--opt OPT', '-o', 'desc')
    c.separator "specials:"
    c.add('switch', true, :option_type => :switch)
    c.add('flag', true, :option_type => :flag)
    c.add('list', [1,2,3], :option_type => :list, :long => '--list', :split => ',')
    
    expected = %Q{
    -o, --opt OPT                    desc
specials:
        --[no-]switch
        --flag
        --list LIST
}
    assert_equal expected, "\n" + c.to_s
  end
  
  def test_to_s_for_options_without_long
    c.add('flag', false, :long => nil, :short => :f, :desc => 'desc')
    c.add('opt', nil, :long => nil, :short => :o, :arg_name => 'OPT', :desc => 'desc')
    c.add('alt', nil, :desc => 'desc')
    expected = %Q{
    -f                               desc
    -o OPT                           desc
        --alt ALT                    desc
}
    assert_equal expected, "\n" + c.to_s
  end
end