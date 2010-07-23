require 'config_parser/switch'

class ConfigParser
  
  # Represents an option registered with ConfigParser.
  class Option < Flag
    
    # The argument name printed by to_s.  If arg_name
    # is nil, no value will be parsed for self.
    attr_reader :arg_name
    
    # Initializes a new Option using attribute values for :long, :short,
    # :arg_name, and :desc.  The long and short values are transformed 
    # using Utils.longify and Utils.shortify, meaning both bare strings
    # (ex 'opt', 'o') and full switches ('--opt', '-o') are valid.
    def initialize(attrs={})
      super
      @arg_name = attrs[:arg_name] || (name ? name.to_s.upcase : nil)
    end
    
    def parse(switch, value, argv=[], config={})
      if value.nil?
        raise "no value provided for: #{switch}" if argv.empty?
        value = argv.shift
      end
      assign(config, callback ? callback.call(value) : value)
    end
    
    private
    
    def header_str # :nodoc:
      "    #{short_str}#{long_str} #{arg_name}"
    end
  end
end