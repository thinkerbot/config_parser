require 'config_parser/flag'

class ConfigParser
  
  # Switch represents a special type of Option where both positive (--flag)
  # and negative (--no-flag) flags map to self.
  class Switch < Flag
    
    # The negative long flag, determined from long if not set otherwise.
    attr_reader :negative_long
    
    def initialize(attrs={})
      attrs[:default] = true unless attrs.has_key?(:default)
      super
      
      raise ArgumentError, "no long specified" unless long
      @negative_long = attrs[:negative_long] || prefix_long(long, 'no-')
    end
    
    # Returns an array of non-nil flags mapping to self (ie [long,
    # negative_long, short]).
    def flags
      [long, negative_long, short].compact
    end
    
    # Assigns true into config for positive flags and false for negative
    # flags.  If specified, the callback is called with the boolean to
    # determine the assigned value.  Raises an error if a value is provided
    # (switches take none).
    def parse(flag, value, argv=[], config={})
      raise "value specified for switch: #{flag}" if value
      
      value = (flag == negative_long ? !default : default)
      value = callback.call(value) if callback
      
      assign(value, config)
      value
    end

    private
    
    # helper returning long formatted for to_s
    def long_str # :nodoc:
      long ? prefix_long(long, '[no-]') : ''
    end
  end
end