require 'config_parser/flag'

class ConfigParser
  
  # Switch represents a special type of Option where both positive (--flag)
  # and negative (--no-flag) flags map to self.
  class Switch < Flag
    
    # The negative long flag, determined from long if not set otherwise.
    attr_reader :negative_long
    
    def initialize(attrs={})
      super
      raise ArgumentError, "no long specified" unless long
      @negative_long = attrs[:negative_long] || prefix_long(long, 'no-')
    end
    
    # Returns an array of non-nil flags mapping to self (ie [long,
    # negative_long, short]).
    def flags
      [long, negative_long, short].compact
    end
    
    # Calls the block with false if the negative long is specified, or calls
    # the block with true in all other cases.  Raises an error if a value is
    # specified.
    def parse(flag, value, argv=[], config={})
      raise "value specified for switch: #{flag}" if value
      value = flag == negative_long ? false : true
      assign(config, callback ? callback.call(value) : value)
    end

    private
    
    # helper returning long formatted for to_s
    def long_str # :nodoc:
      long ? prefix_long(long, '[no-]') : ''
    end
  end
end