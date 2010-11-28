require 'config_parser/option'

class ConfigParser
  
  # List represents a special type of Option where multiple values may be
  # assigned to the same key.
  class List < Option
    
    # The delimiter on which to split single values into multiple values; use
    # nil to prevent splitting.
    attr_reader :delimiter
    
    def initialize(attrs={})
      super
      
      @delimiter = attrs.has_key?(:delimiter) ? attrs[:delimiter] : DELIMITER
      @default = split(@default)
    end
    
    # Splits the value into multiple values, and then process as usual.
    def process(value)
      split(value).collect {|val| super(val) }
    end
    
    # Assigns the values to config.  Multiple calls to assign will concatenate
    # (ie when assigned is true) new values onto the existing values.  As
    # usual, no values are assigned if key is not set.  Returns config.
    def assign(config, values)
      if key
        nest_config = nest(config)
        
        unless assigned
          nest_config.delete(key)
        end
        
        array = (nest_config[key] ||= [])
        array.concat(values)
      end
      
      @assigned = true
      config
    end
    
    # Splits string values along the delimiter, if specified.  Returns array
    # values directly, and an empty array for nil.  All other values are
    # arrayified like [obj].
    def split(obj)
      case obj
      when Array  then obj
      when String then delimiter ? obj.split(delimiter) : [obj]
      when nil    then []
      else [obj]
      end
    end
    
    private
    
    def header_str # :nodoc:
      "    #{short_str}#{long_str} #{arg_name}..."
    end
  end
end