require 'config_parser/utils'

class ConfigParser
  class Flag
    include Utils
    
    attr_reader :name
    
    # The short switch mapping to self
    attr_reader :short 
    
    # The long switch mapping to self
    attr_reader :long
    
    # The description printed by to_s
    attr_reader :desc
    
    attr_reader :callback
    
    def initialize(attrs={}, &callback)
      @name  = attrs[:name]
      @short = shortify(attrs[:short])
      @long  = longify(attrs.has_key?(:long) ? attrs[:long] : name)
      @desc  = attrs[:desc]
      @callback = callback
    end
    
    # Returns an array of non-nil switches mapping to self (ie [long, short]).
    def switches
      [long, short].compact
    end
    
    def parse(switch, value, argv=[], config={})
      raise "value specified for flag: #{switch}" if value
      assign(config, callback ? callback.call : true)
    end
    
    def assign(config, value)
      config[name] = value if name
      value
    end
    
    # Formats self as a help string for use on the command line.
    def to_s
      lines = wrap(desc.to_s, 43)
      
      header =  header_str
      header = header.length > 36 ? header.ljust(80) : (LINE_FORMAT % [header, lines.shift])
      
      if lines.empty?
        header
      else
        lines.collect! {|line| LINE_FORMAT % [nil, line] }
        "#{header}\n#{lines.join("\n")}"
      end
    end
    
    private
    
    def header_str # :nodoc:
      "    #{short_str}#{long_str}"
    end
    
    # helper returning short formatted for to_s
    def short_str # :nodoc:
      case
      when short && long then "#{short}, "
      when short then "#{short}"
      else '    '
      end
    end
    
    # helper returning long formatted for to_s
    def long_str # :nodoc:
      long
    end
  end
end