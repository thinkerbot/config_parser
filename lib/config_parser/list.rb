require 'config_parser/option'

class ConfigParser
  class List < Option
    
    # The default split character for multiple values
    DEFAULT_SPLIT = ','
    
    # The maximum number of values that may be specified.
    attr_reader :limit
    
    # The sequence on which to split single values into multiple values. Set
    # to nil to prevent split.
    attr_reader :split
    
    def initialize(attrs={})
      super
      @limit = attrs[:n]
      @split = attrs.has_key?(:split) ? attrs[:split] : DEFAULT_SPLIT
    end
    
    # List assigns configs by pushing the value onto an array, rather than
    # directly setting it onto config.  As usual, no value is assigned if key
    # is not set.  Returns value (the input, not the array).
    def assign(config, value=default)
      if key
        nest_config = nest(config)
        array = (nest_config[key] ||= [])
        array.concat(split ? value.split(split) : [value])
      
        if limit && array.length > limit
          raise "too many assignments: #{key.inspect}"
        end
      end
      
      config
    end
  end
end