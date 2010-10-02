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
  # Returns option.
  #
  # If override is specified, options with conflicting flags are removed and
  # no error is raised.  Note that this may remove multiple options.
  def register(option, override=false)
    return nil if option.nil?
    
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
    
    option
  end
  
  # Unregisters the option by removing it from the registry and options.
  # Returns option.
  def unregister(option)
    @registry.delete(option)
    @options.delete_if {|key, value| option == value }
    option
  end
  
  # Sorts options in the registry as specified by the block.  Groups of
  # options as delimited by separators are sorted independently.  If no
  # block is given, options are sorted by their long and short keys.
  def sort_opts!(&block)
    block ||= lambda {|option| option.long || option.short }
    
    splits = []
    current = []
    
    options = self.options.values.uniq
    registry.each do |option|
      if options.include?(option)
        current << option
      else
        splits << current
        splits << option
        current = []
      end
    end
    
    splits << current
    @registry = splits.collect {|split| split.kind_of?(Array) ? split.sort_by(&block) : split }
    @registry.flatten!
    
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
  #   psr.on('-k', 'description', :long => '--key', :option_type => :list) do |args|
  #     # ...
  #   end
  #   
  # The trailing hash wins if there is any overlap in the parsed attributes
  # and those provided by the hash.
  def on(*args, &block)
    register new_option(args, &block)
  end
  
  # Same as on, but overrides options with overlapping flags.
  def on!(*args, &block)
    register new_option(args, &block), true
  end
  
  # An alternate syntax for on, where the key and default attributes are set
  # by the first two args.  Like on, add can define option attributes using a
  # series of args or with a trailing hash.
  #
  # These are equivalent:
  #
  #   add(:opt, 'value', '-s', '--long', :desc => 'description')
  #   on('-s', '--long', :desc => 'description', :key => :opt, :default => 'value')
  #
  def add(key, default=nil, *args, &block)
    attrs = args.last.kind_of?(Hash) ? args.pop : {}
    attrs = attrs.merge(:key => key, :default => default)
    args << attrs
    
    on(*args, &block)
  end
  
  # Removes options by key.  Any options with the specified key are removed.
  # Returns the removed options.
  def rm(key)
    options.values.collect do |option| 
      if option.key == key 
        unregister(option)
      else
        nil
      end
    end.compact
  end
  
  # Parses options from argv in a non-destructive manner. Parsing stops if an
  # argument matching option_break is reached. If preserve_option_break is
  # specified then the option break is preserved in the remaining arguments. 
  # Returns an array of arguments remaining after options have been removed.
  #
  # If a string argv is provided, it will be splits into an array using
  # Shellwords.
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
    while !argv.empty?
      arg = argv.shift
  
      # determine if the arg is an option
      unless option?(arg)
        args << arg
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
    
    args.concat(argv)
    argv.replace(args)
    
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
    type = attrs[:option_type] || guess_option_type(attrs)
    
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
    attrs = parse_attrs(argv).merge(attrs)
    option_class(attrs).new(attrs, &block)
  end
end