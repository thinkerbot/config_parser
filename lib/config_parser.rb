require 'config_parser/list'
require 'config_parser/nest'

autoload(:Shellwords, 'shellwords')

# ConfigParser is the Configurable equivalent of 
# {OptionParser}[http://www.ruby-doc.org/core/classes/OptionParser.html]
# and uses a similar, simplified (see below) syntax to declare options.
#
#   opts = {}
#   parser = ConfigParser.new do |psr|
#     psr.on "-s", "--long LONG", "a standard option" do |value|
#       opts[:long] = value
#     end
#   
#     psr.on "--[no-]switch", "a switch" do |value|
#       opts[:switch] = value
#     end
#
#     psr.on "--flag", "a flag" do
#       # note: no value is parsed; the block 
#       # only executes if the flag is found
#       opts[:flag] = true
#     end
#   end
#
#   parser.parse("a b --long arg --switch --flag c")   # => ['a', 'b', 'c']
#   opts             # => {:long => 'arg', :switch => true, :flag => true}
#
# ConfigParser formalizes this pattern of setting values in a hash as they
# occur, and adds the ability to specify default values.  The syntax is
# not quite as friendly as for ordinary options, but meshes well with
# Configurable classes:
#
#   psr = ConfigParser.new
#   psr.define(:key, 'default', :desc => 'a standard option')
#
#   psr.parse('a b --key option c')                 # => ['a', 'b', 'c']
#   psr.config                                      # => {:key => 'option'}
#
#   psr.parse('a b c')                              # => ['a', 'b', 'c']
#   psr.config                                      # => {:key => 'default'}
#
# And now directly from a Configurable class, the equivalent of the
# original example:
#
#   class ConfigClass
#     include Configurable
#
#     config :long, 'default', :short => 's'  # a standard option
#     config :switch, false, &c.switch        # a switch
#     config :flag, false, &c.flag            # a flag
#   end
#
#   psr = ConfigParser.new
#   psr.add(ConfigClass.configurations)
#
#   psr.parse("a b --long arg --switch --flag c")   # => ['a', 'b', 'c']
#   psr.config    # => {:long => 'arg', :switch => true, :flag => true}
#
#   psr.parse("a b --long=arg --no-switch c")       # => ['a', 'b', 'c']
#   psr.config    # => {:long => 'arg', :switch => false, :flag => false}
#
#   psr.parse("a b -sarg c")                        # => ['a', 'b', 'c']
#   psr.config    # => {:long => 'arg', :switch => false, :flag => false}
#
# As you might expect, config attributes are used by ConfigParser to 
# correctly build a corresponding option.  In configurations like :switch, 
# the block implies the {:type => :switch} attribute and so the
# config is made into a switch-style option by ConfigParser.
#
# Use the to_s method to convert a ConfigParser into command line
# documentation:
#
#   "\nconfigurations:\n#{psr.to_s}"
#   # => %q{
#   # configurations:
#   #     -s, --long LONG                  a standard option
#   #         --[no-]switch                a switch
#   #         --flag                       a flag
#   # }
#
# ==== Simplifications
#
# ConfigParser simplifies the OptionParser syntax for 'on'.  ConfigParser does
# not support automatic conversion of values, gets rid of 'optional' arguments
# for options, and only supports a single description string.  Hence:
#
#   psr = ConfigParser.new
#  
#   # incorrect, raises error as this will look
#   # like multiple descriptions are specified
#   psr.on("--delay N", 
#          Float,
#          "Delay N seconds before executing")        # !> ArgumentError
#
#   # correct
#   psr.on("--delay N", "Delay N seconds before executing") do |value|
#     value.to_f
#   end
#
#   # this ALWAYS requires the argument and raises
#   # an error because multiple descriptions are
#   # specified
#   psr.on("-i", "--inplace [EXTENSION]",
#          "Edit ARGV files in place",
#          "  (make backup if EXTENSION supplied)")   # !> ArgumentError
#
#   # correct
#   psr.on("-i", "--inplace EXTENSION", 
#          "Edit ARGV files in place\n  (make backup if EXTENSION supplied)")
#
#
class ConfigParser
  include Utils
  
  # Returns an array of the options registered with self, in the order in
  # which they were added.  Separators are also stored in the registry.
  attr_reader :registry
  
  # A hash of (switch, Option) pairs mapping command line
  # switches like '-s' or '--long' to the Option that
  # handles them.
  attr_reader :options
  
  # The hash receiving configurations produced by parse.
  attr_accessor :config
  
  attr_accessor :option_break
  
  attr_accessor :preserve_option_break
  
  # Initializes a new ConfigParser and passes it to the block, if given.
  def initialize(config={}, opts={})
    opts = {
      :option_break => OPTION_BREAK,
      :preserve_option_break => false
    }.merge(opts)
    
    @registry = []
    @options = {}
    @config = config
    
    @option_break = opts[:option_break]
    @preserve_option_break = opts[:preserve_option_break]
    
    yield(self) if block_given?
  end
  
  # Returns the config value for key.
  def [](key)
    config[key]
  end
  
  # Sets the config value for key.
  def []=(key, value)
    config[key] = value
  end
  
  # Adds a separator string to self, used in to_s.
  def separator(str)
    @registry << str
  end

  # Registers the option with self by adding opt to options and mapping the
  # opt switches. Raises an error for conflicting switches.
  #
  # If override is specified, options with conflicting switches are removed
  # and no error is raised.  Note that this may remove multiple options.
  def register(opt, override=false)
    if override
      existing = opt.switches.collect do |switch|
        @options.delete(switch)
      end
      @registry -= existing
    end
    
    unless @registry.include?(opt)
      @registry << opt
    end
    
    opt.switches.each do |switch|
      case @options[switch]
      when opt then next
      when nil then @options[switch] = opt
      else raise ArgumentError, "switch is already mapped to a different option: #{switch}"
      end
    end

    opt
  end
  
  # Constructs an Option using args and registers it with self.  Args may
  # contain (in any order) a short switch, a long switch, and a description
  # string.  Either the short or long switch may signal that the option
  # should take an argument by providing an argument name.
  #
  #   psr = ConfigParser.new
  #
  #   # this option takes an argument
  #   psr.on('-s', '--long ARG_NAME', 'description') do |value|
  #     # ...
  #   end
  #
  #   # so does this one
  #   psr.on('-o ARG_NAME', 'description') do |value|
  #     # ...
  #   end
  #   
  #   # this option does not
  #   psr.on('-f', '--flag') do
  #     # ...
  #   end
  #
  # A switch-style option can be specified by prefixing the long switch with
  # '--[no-]'.  Switch options will pass true to the block for the positive
  # form and false for the negative form.
  #
  #   psr.on('--[no-]switch') do |value|
  #     # ...
  #   end
  #
  # Args may also contain a trailing hash defining all or part of the option:
  #
  #   psr.on('-k', :long => '--key', :desc => 'description')
  #     # ...
  #   end
  #
  def on(*args, &block)
    register new_option(args, &block)
  end
  
  # Same as on, but overrides options with overlapping switches.
  def on!(*args, &block)
    register new_option(args, &block), true
  end
  
  # Defines and registers a config-style option with self.  Define does not
  # take a block; the default value will be added to config, and any parsed
  # value will override the default.  Normally the key will be turned into
  # the long switch; specify an alternate long, a short, description, etc
  # using attributes.
  #
  #   psr = ConfigParser.new
  #   psr.define(:one, 'default')
  #   psr.define(:two, 'default', :long => '--long', :short => '-s')
  #
  #   psr.parse("--one one --long two")
  #   psr.config             # => {:one => 'one', :two => 'two'}
  #
  # Define support several types of configurations that define a special 
  # block to handle the values parsed from the command line.  See the 
  # 'setup_<type>' methods in Utils.  Any type with a corresponding setup
  # method is valid:
  #   
  #   psr = ConfigParser.new
  #   psr.define(:flag, false, :type => :flag)
  #   psr.define(:switch, false, :type => :switch)
  #   psr.define(:list, [], :type => :list)
  #
  #   psr.parse("--flag --switch --list one --list two --list three")
  #   psr.config             # => {:flag => true, :switch => true, :list => ['one', 'two', 'three']}
  #
  # New, valid types may be added by implementing new setup_<type> methods
  # following this pattern:
  #
  #   module SpecialType
  #     def setup_special(key, default_value, attributes)
  #       # modify attributes if necessary
  #       attributes[:long] = "--#{key}"
  #       attributes[:arg_name] = 'ARG_NAME'
  # 
  #       # return a block handling the input
  #       lambda {|input| config[key] = input.reverse }
  #     end
  #   end
  #
  #   psr = ConfigParser.new.extend SpecialType
  #   psr.define(:opt, false, :type => :special)
  #
  #   psr.parse("--opt value")
  #   psr.config             # => {:opt => 'eulav'}
  #
  # The :hidden type causes no configuration to be defined.  Raises an error if
  # key is already set by a different option.
  def define(key, default=nil, attrs={}, &block)
    attrs = attrs.merge(:name => key, :default => default)
    type = attrs.delete(:type) || :option
    
    clas = option_class(type)
    clas ? register(clas.new(attrs, &block)) : nil
  end
  
  # Parses options from argv in a non-destructive manner and returns an
  # array of arguments remaining after options have been removed. If a 
  # string argv is provided, it will be splits into an array using 
  # Shellwords.
  #
  # ==== Options
  #
  # clear_config:: clears the currently parsed configs (true)
  # add_defaults:: adds the default values to config (true)
  # ignore_unknown_options:: causes unknown options to be ignored (false)
  #
  def parse(argv=ARGV)
    argv = argv.dup unless argv.kind_of?(String)
    parse!(argv)
  end
  
  # Same as parse, but removes parsed args from argv.
  def parse!(argv=ARGV)
    argv = Shellwords.shellwords(argv) if argv.kind_of?(String)
    
    args = []
    remainder = scan(argv) {|arg| args << arg }
    args.concat(remainder)
    argv.replace(args)
    
    argv
  end
  
  def scan(argv=ARGV)
    while !argv.empty?
      arg = argv.shift
  
      # determine if the arg is an option
      unless arg.kind_of?(String) && arg[0] == ?-
        yield(arg)
        next
      end
      
      # add the remaining args and break
      # for the option break
      if option_break === arg
        argv.unshift(arg) if preserve_option_break
        break
      end
      
      # split the arg...
      # switch= $1
      # value = $2
      arg =~ LONG_OPTION || arg =~ SHORT_OPTION || arg =~ ALT_SHORT_OPTION 
  
      # lookup the option
      unless option = @options[$1]
        raise "unknown option: #{$1 || arg}"
      end
      
      option.parse($1, $2, argv, config)
    end
    
    argv
  end
  
  # Converts the options and separators in self into a help string suitable for
  # display on the command line.
  def to_s
    @registry.collect do |option|
      option.to_s.rstrip
    end.join("\n") + "\n"
  end
  
  protected
  
  def option_class(type)
    case type
    when :option then Option
    when :flag   then Flag
    when :switch then Switch
    when :list   then List
    when :hidden then nil
    else raise "unknown option type: #{type}"
    end
  end
  
  # helper to parse an option from an argv.  new_option is used
  # by on and on! to generate options
  def new_option(argv, &block) # :nodoc:
    attrs = argv.last.kind_of?(Hash) ? argv.pop : {}
    
    argv.each do |arg|
      case arg
      when OPTION
        attrs[$2.length == 1 ? :short : :long] = $1
        attrs[:arg_name] = $3 if $3
      
      when SWITCH
        attrs[:long] = $1 ? "--#{$1}:#{$3}" : "--#{$3}"
        attrs[:negative_long] = $1 ? "--#{$1}:#{$2}-#{$3}" : "--#{$2}-#{$3}"
        attrs[:type] = :switch
        raise ArgumentError.new("arg_name specified for switch: #{$4}") if $4
      
      when /\A-/
        raise ArgumentError.new("invalid switch: #{arg.inspect}")
        
      else
        attrs[:desc] = arg
      end
    end
    
    type = attrs.delete(:type)
    type ||= (attrs.has_key?(:arg_name) ? :option : :flag)
    
    clas = option_class(type)
    clas ? clas.new(attrs, &block) : nil
  end
end