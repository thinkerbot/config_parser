require 'config_parser/option'

class ConfigParser
  class List < Option
    
    # The default split character for multiple values
    DELIMITER = ','
    
    # The maximum number of values that may be specified.
    attr_reader :limit
    
    # The sequence on which to split single values into multiple values. Set
    # to nil to prevent split.
    attr_reader :delimiter
    
    def initialize(attrs={})
      super
      
      @delimiter = attrs.has_key?(:delimiter) ? attrs[:delimiter] : DELIMITER
      @limit   = attrs[:limit]
      @default = split(@default)
    end
    
    def process(value)
      super split(value)
    end
    
    # List assigns configs by pushing the value onto an array, rather than
    # directly setting it onto config.  As usual, no value is assigned if key
    # is not set.  Returns value (the input, not the array).
    def assign(config, values=default)
      if key
        nest_config = nest(config)
        array = (nest_config[key] ||= [])
        array.concat(values)
      
        if limit && array.length > limit
          raise "too many assignments for #{key.inspect}"
        end
      end
      
      config
    end
    
    def split(str)
      case str
      when Array  then str
      when String then delimiter ? str.split(delimiter) : [str]
      when nil    then []
      else [str]
      end
    end
  end
end