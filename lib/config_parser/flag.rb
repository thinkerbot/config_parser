require 'config_parser/utils'

class ConfigParser
  
  # Represents a boolean flag-style option. Flag handles the parsing of
  # specific flags, and provides hooks for processing the various types of
  # options (Switch, Option, List).
  class Flag
    include Utils
    
    # The config key
    attr_reader :key
    
    # The config nesting keys
    attr_reader :nest_keys
    
    # The default value
    attr_reader :default
    
    # The short flag mapping to self
    attr_reader :short 
    
    # The long flag mapping to self
    attr_reader :long
    
    # The description printed by to_s
    attr_reader :desc
    
    # A callback for processing values
    attr_reader :callback
    
    def initialize(attrs={}, &callback)
      @key       = attrs[:key]
      @nest_keys = attrs[:nest_keys]
      @default   = attrs[:default]
      @short     = shortify(attrs[:short])
      @long      = longify(attrs.has_key?(:long) ? attrs[:long] : default_long)
      @desc      = attrs[:desc]
      @callback  = callback
    end
    
    # Returns an array of flags mapping to self (ie [long, short]).
    def flags
      [long, short].compact
    end
    
    # Parse handles the parsing of flags, which happens in three steps:
    #
    # * determine the value (occurs in parse)
    # * process the value
    # * assign the result into config
    #
    # Flag uses !default as the value (such that the flag indicates true if
    # the default is false) then passes the value to process, and then assign.
    # Raises and error if provided a value directly (flags always determine
    # their value based on the default).
    #
    #--
    # Implementation Note
    #
    # The compact syntax for short flags is handled through parse by
    # unshifting remaining shorts (ie value) back onto argv.  This allows
    # shorts that consume a value to take the remainder as needed.  As an
    # example to clarify, assume -x -y are flags where -x takes a value and -y
    # does not.  These are equivalent:
    #
    #   -x value -y
    #   -xvalue -y
    #   -y -xvalue
    #   -yxvalue
    #         
    # Whereas this is not:
    #
    #   -xyvalue                   # x receives 'yvalue' not 'value'
    #
    # Parse handles the compact short syntax splitting '-yxvalue' into '-y',
    # 'xvalue'. Then '-y' determines whether or not it needs a values; if not
    # '-xvalue' gets unshifted to argv and parsing continues as if '-y
    # -xvalue' were the original arguments.
    def parse(flag, value=nil, argv=[], config={})
      unless value.nil?
        if flag == short
          argv.unshift "-#{value}"
        else
          raise "value specified for #{flag}: #{value.inspect}"
        end
      end
      
      value = (default.nil? ? true : !default)
      assign(config, process(value))
    end
    
    # Process the value by calling the callback, if specified, with the value
    # and returns the result.  Returns value if no callback is specified.
    def process(value)
      callback ? callback.call(value) : value
    end
    
    # Assign the value to the config hash, if key is set.  Returns config.
    def assign(config, value=default)
      if key
        nest_config = nest(config)
        nest_config[key] = value
      end
      
      config
    end
    
    # Returns the nested config hash for config, as specified by nest_keys.
    def nest(config)
      nest_keys.each do |key|
        config = (config[key] ||= {})
      end if nest_keys
      
      config
    end
    
    # Formats self as a help string for use on the command line.
    def to_s
      lines = wrap(desc.to_s, 43)
      
      header =  header_str
      header = header.length > 36 ? header.ljust(80) : (LINE_FORMAT % [header, lines.shift])
      
      if lines.empty?
        header
      else
        lines.collect! {|line| LINE_FORMAT % [nil, line] }
        "#{header}\n#{lines.join("\n")}"
      end
    end
    
    # Returns an inspect string.
    def inspect
      "#<#{self.class}:#{object_id} key=#{key.inspect} default=#{default.inspect} long=#{long.inspect} short=#{short.inspect}>"
    end
    
    private
    
    def header_str # :nodoc:
      "    #{short_str}#{long_str}"
    end
    
    def short_str # :nodoc:
      case
      when short && long then "#{short}, "
      when short then "#{short}"
      else '    '
      end
    end
    
    def long_str # :nodoc:
      long
    end
    
    def default_long # :nodoc:
      nest_keys ? (nest_keys + [key]).join(':') : key
    end
  end
end