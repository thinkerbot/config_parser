require 'config_parser/utils'

class ConfigParser
  class Flag
    include Utils
    
    # The config key
    attr_reader :key
    
    # The short flag mapping to self
    attr_reader :short 
    
    # The long flag mapping to self
    attr_reader :long
    
    # The description printed by to_s
    attr_reader :desc
    
    # A callback for processing values
    attr_reader :callback
    
    def initialize(attrs={}, &callback)
      @key  = attrs[:key]
      @short = shortify(attrs[:short])
      @long  = longify(attrs.has_key?(:long) ? attrs[:long] : key)
      @desc  = attrs[:desc]
      @callback = callback
    end
    
    # Returns an array of non-nil flags mapping to self (ie [long, short]).
    def flags
      [long, short].compact
    end
    
    # Assigns true into config and raises an error if a value is provided
    # (flags take none).  The callback will be called if specified to provide
    # the assigned value.
    #
    # Note this is the entry point for handling different types of
    # configuration flags.
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
    def parse(flag, value, argv=[], config={})
      unless value.nil?
        if flag == short
          argv.unshift "-#{value}"
        else
          raise "value specified for flag: #{flag}"
        end
      end
      
      assign(config, callback ? callback.call : true)
    end
    
    # Assign the value to the config hash, if key is set.  Returns value.
    def assign(config, value)
      config[key] = value if key
      value
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
    
    private
    
    def header_str # :nodoc:
      "    #{short_str}#{long_str}"
    end
    
    # helper returning short formatted for to_s
    def short_str # :nodoc:
      case
      when short && long then "#{short}, "
      when short then "#{short}"
      else '    '
      end
    end
    
    # helper returning long formatted for to_s
    def long_str # :nodoc:
      long
    end
  end
end