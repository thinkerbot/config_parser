require 'config_parser/list'
autoload(:Shellwords, 'shellwords')

# ConfigParser is an option parser that formalizes the pattern of setting
# parsed options into a hash. ConfigParser provides a similar declaration
# syntax as
# {OptionParser}[http://www.ruby-doc.org/core/classes/OptionParser.html] but
# additionally supports option declaration using an attributes hash.
class ConfigParser
  include Utils
  
  # Returns an array of the options registered with self, in the order in
  # which they were added.  Separators are also stored in the registry.
  attr_reader :registry
  
  # A hash of (flag, Option) pairs mapping command line flags like '-s' or
  # '--long' to the Option that handles them.
  attr_reader :options
  
  # The hash receiving configs.
  attr_accessor :config
  
  # The argument to stop processing options
  attr_accessor :option_break
  
  # Set to true to preserve the option break
  attr_accessor :preserve_option_break
  
  # Set to true to assign config defaults on parse
  attr_accessor :assign_defaults
  
  # Initializes a new ConfigParser and passes it to the block, if given.
  def initialize(config={}, opts={})
    opts = {
      :option_break => OPTION_BREAK,
      :preserve_option_break => false,
      :assign_defaults => true
    }.merge(opts)
    
    @registry = []
    @options = {}
    @config = config
    @option_break = opts[:option_break]
    @preserve_option_break = opts[:preserve_option_break]
    @assign_defaults = opts[:assign_defaults]
    
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

  # Registers the option with self by adding it to the registry and mapping
  # the option flags into options. Raises an error for conflicting flags.
  # Returns self.
  #
  # If override is specified, options with conflicting flags are removed and
  # no error is raised.  Note that this may remove multiple options.
  def register(option, override=false)
    return if option.nil?
    
    if override
      existing = option.flags.collect {|flag| @options.delete(flag) }
      @registry -= existing
    end
    
    unless @registry.include?(option)
      @registry << option
    end
    
    option.flags.each do |flag|
      current = @options[flag]
      
      if current && current != option
        raise ArgumentError, "already mapped to a different option: #{flag}"
      end
      
      @options[flag] = option
    end
    
    self
  end
  
  # Unregisters the option by removing it from the registry and options.
  # Returns self.
  def unregister(option)
    @registry.delete(option)
    @options.delete_if {|key, value| option == value }
    self
  end
  
  # Constructs an Option using args and registers it with self. The args may
  # contain (in any order) a short switch, a long switch, and a description
  # string. A block may be provided to process values for the option.
  #
  # The option type (flag, switch, list, or option) is guessed from the args,
  # and affects what is passed to the block.
  #
  #   psr = ConfigParser.new
  #
  #   # options take an argument on the long
  #   # and receive the arg in the block
  #   psr.on('-s', '--long ARG_NAME', 'description') do |arg|
  #     # ...
  #   end
  #
  #   # the argname can be specified on a short
  #   psr.on('-o ARG_NAME') do |arg|
  #     # ...
  #   end
  #     
  #   # use an argname with commas to make a list,
  #   # an array of values is passed to the block
  #   psr.on('--list A,B,C') do |args|
  #     # ...
  #   end
  #
  #   # flags specify no argument, and the
  #   # block takes no argument
  #   psr.on('-f', '--flag') do
  #     # ...
  #   end
  #
  #   # switches look like this; they get true
  #   # or false in the block
  #   psr.on('--[no-]switch') do |bool|
  #     # ...
  #   end
  #
  # If this is too ambiguous (and at times it is), provide a trailing hash
  # defining all or part of the option:
  #
  #   psr.on('-k', 'description', :long => '--key', :type => :list) do |args|
  #     # ...
  #   end
  #         
  def on(*args, &block)
    option = new_option(args, &block)
    register option
    option
  end
  
  # Same as on, but overrides options with overlapping flags.
  def on!(*args, &block)
    option = new_option(args, &block)
    register option, true
    option
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
  def add(key, default=nil, *args, &block)
    attrs = args.last.kind_of?(Hash) ? args.pop : {}
    attrs = attrs.merge(:key => key, :default => default)
    args << attrs
    
    on(*args, &block)
  end
  
  def rm(key)
    opts = options.values.select {|option| option.key == key }
    opts.each {|option| unregister(option) }
    opts
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
    
    if assign_defaults
      registry.each do |option|
        next unless option.respond_to?(:assign)
        option.assign(config)
      end
    end
    
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
      
      flag, value = arg, nil
      
      # try the flag directly
      unless option = @options[flag]
        
        # then try --opt=value syntax
        flag, value = flag.split('=', 2)
        
        # then try -ovalue syntax
        if value.nil? && flag[1] != ?-
          flag, value = flag[0, 2], flag[2, flag.length - 2]
        end
        
        unless option = @options[flag]
          raise "unknown option: #{flag}"
        end
      end
      
      option.parse(flag, value, argv, config)
    end
    
    argv
  end
  
  # Converts the options and separators in self into a help string suitable
  # for display on the command line.
  def to_s
    @registry.collect do |option|
      option.to_s.rstrip
    end.join("\n") + "\n"
  end
  
  protected
  
  def option_class(attrs) # :nodoc:
    type = attrs[:type] || guess_type(attrs)
    
    case type
    when :option then Option
    when :flag   then Flag
    when :switch then Switch
    when :list   then List
    when Class   then type
    else raise "unknown option type: #{type}"
    end
  end
  
  # helper to parse an option from an argv.  new_option is used
  # by on and on! to generate options
  def new_option(argv, &block) # :nodoc:
    attrs = argv.last.kind_of?(Hash) ? argv.pop : {}
    attrs = attrs.merge parse_attrs(argv)
    option_class(attrs).new(attrs, &block)
  end
end