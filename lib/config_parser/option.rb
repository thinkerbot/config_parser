require 'config_parser/switch'

class ConfigParser
  
  # Represents an option registered with ConfigParser.
  class Option < Flag
    DEFAULT_ARGNAME = 'VALUE'
    
    # The argument name printed by to_s.
    attr_reader :arg_name
    
    def initialize(attrs={})
      super
      @arg_name = attrs[:arg_name] || (key ? key.to_s.upcase : DEFAULT_ARGNAME)
    end
    
    # Parse the flag and value.  If no value is provided and a value is
    # required, then a value is shifted off of argv.  Calls the callback
    # with the value, if specified, and assigns the result.
    def parse(flag, value, argv=[], config={})
      if value.nil?
        unless value = next_arg(argv)
          raise "no value provided for: #{flag}"
        end
      end
      assign(config, callback ? callback.call(value) : value)
    end
    
    private
    
    def next_arg(argv) # :nodoc:
      arg = argv[0]
      (arg.kind_of?(String) && arg[0] == ?-) ? default : argv.shift
    end
    
    def header_str # :nodoc:
      "    #{short_str}#{long_str} #{arg_name}"
    end
  end
end