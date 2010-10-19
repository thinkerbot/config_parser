require 'config_parser/switch'

class ConfigParser
  
  # An Option represents a Flag that takes a value.
  class Option < Flag
    
    # The default argument name
    DEFAULT_ARGNAME = 'VALUE'
    
    # Matches optional argnames
    OPTIONAL = /\A\[.*\]\z/
    
    # The argument name printed by to_s.
    attr_reader :arg_name
    
    # Set to true to make the argument optional
    attr_reader :optional
    
    def initialize(attrs={})
      super
      @arg_name = attrs[:arg_name] || (key ? key.to_s.upcase : DEFAULT_ARGNAME)
      @optional = (attrs.has_key?(:optional) ? attrs[:optional] : (arg_name =~ OPTIONAL ? true : false))
    end
    
    # Parse the flag and value.  If no value is provided and a value is
    # required, then a value is shifted off of argv.  The value is then
    # processed and assigned into config.
    def parse(flag, value=nil, argv=[], config={})
      if value.nil?
        unless value = next_arg(argv)
          if optional
            value = default
          else
            raise "no value provided for: #{flag}"
          end
        end
      end
      
      assign(config, process(value))
    end
    
    private
    
    def header_str # :nodoc:
      "    #{short_str}#{long_str} #{arg_name}"
    end
  end
end