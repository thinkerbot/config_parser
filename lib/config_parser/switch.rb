require 'config_parser/flag'

class ConfigParser
  
  # Switch represents a special type of Option where both positive (--flag)
  # and negative (--no-flag) flags map to self.
  class Switch < Flag
    
    attr_reader :prefix
    
    # The negative long flag, determined from long.
    attr_reader :nolong
    
    def initialize(attrs={})
      attrs[:default] = true unless attrs.has_key?(:default)
      super
      
      raise ArgumentError, "no long specified" unless long
      @prefix = attrs[:prefix] || 'no'
      @nolong = prefix_long(long, "#{prefix}-")
    end
    
    # Returns an array of non-nil flags mapping to self (ie [long,
    # nolong, short]).
    def flags
      [long, nolong, short].compact
    end
    
    # Assigns true into config for positive flags and false for negative
    # flags.  If specified, the callback is called with the boolean to
    # determine the assigned value.  Raises an error if a value is provided
    # (switches take none).
    def parse(flag, value=nil, argv=[], config={})
      raise "value specified for switch: #{flag}" if value
      
      value = (flag == nolong ? !default : default)
      value = callback.call(value) if callback
      
      assign(config, value)
      value
    end

    private
    
    # helper returning long formatted for to_s
    def long_str # :nodoc:
      prefix_long(long, "[#{prefix}-]")
    end
  end
end