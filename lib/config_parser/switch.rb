require 'config_parser/flag'

class ConfigParser
  
  # Switch represents a special type of Option where both positive (--flag)
  # and negative (--no-flag) flags map to self.
  class Switch < Flag
    
    # The negative mapping prefix, defaults to 'no'
    attr_reader :prefix
    
    # The negative long flag, determined from long and prefix.
    attr_reader :negative_long
    
    def initialize(attrs={})
      attrs[:default] = true unless attrs.has_key?(:default)
      super
      
      raise ArgumentError, "no long specified" unless long
      @prefix = attrs[:prefix] || 'no'
      @negative_long = prefix_long(long, "#{prefix}-")
    end
    
    # Returns an array of flags mapping to self (ie [long, negative_long, short]).
    def flags
      [long, negative_long, short].compact
    end
    
    # Assigns default into config for positive flags and !default for negative
    # flags. The boolean value is then processed and assigned into config.
    # Raises an error if a value is provided (switches take none).
    def parse(flag, value=nil, argv=[], config={})
      raise "value specified for #{flag}: #{value.inspect}" if value
      
      value = (flag == negative_long ? !default : default)
      assign(config, process(value))
    end

    private
    
    def long_str # :nodoc:
      prefix_long(long, "[#{prefix}-]")
    end
  end
end