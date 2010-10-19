require 'config_parser/option'

class ConfigParser
  
  # List represents a special type of Option where multiple values may be
  # assigned to the same key.
  class List < Option
    
    # The default split character for multiple values
    DELIMITER = ','
    
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
    
    # Assigns the values to config by concatenating onto an array, rather than
    # directly setting into config.  As usual, no value is assigned if key is
    # not set.
    def assign(config, values=default)
      if key
        nest_config = nest(config)
        array = (nest_config[key] ||= [])
        array.concat(values)
      end
      
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
  end
end