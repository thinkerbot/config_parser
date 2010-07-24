class ConfigParser
  
  # A medly of methods used throughout the ConfigParser classes.
  module Utils
    module_function
    
    # A format string used by to_s
    LINE_FORMAT = "%-36s %-43s"
    
    # The default option break
    OPTION_BREAK = "--"
    
    # Matches a long flag
    LONG_FLAG = /\A--.+\z/

    # Matches a short flag
    SHORT_FLAG = /\A-.\z/
    
    # Matches a switch declaration (ex: '--[no-]opt', '--nest:[no-]opt').
    # After the match:
    #  
    #   $1:: the nesting prefix ('nest')
    #   $2:: the long flag name ('opt')
    #
    SWITCH = /\A--(.*?)\[no-\](.+)\z/
    
    # Turns the input into a short flag by prefixing '-' (as needed). Raises
    # an error if the input doesn't result in a short flag.   Nils are
    # returned directly.
    #
    #   shortify('-o')         # => '-o'
    #   shortify(:o)           # => '-o'
    #
    def shortify(str)
      return nil if str == nil
  
      str = str.to_s
      str = "-#{str}" unless str[0] == ?-
      
      unless str =~ SHORT_FLAG
        raise ArgumentError, "invalid short flag: #{str}"
      end
      
      str
    end

    # Turns the input into a long flag by prefixing '--' (as needed).  Raises
    # an error if the input doesn't result in a long flag.   Nils are
    # returned directly.
    #
    #   longify('--opt')       # => '--opt'
    #   longify(:opt)          # => '--opt'
    #
    def longify(str)
      return nil if str == nil
  
      str = str.to_s
      str = "--#{str}" unless str[0] == ?-
      
      unless str =~ LONG_FLAG
        raise ArgumentError, "invalid long flag: #{str}"
      end
      
      str
    end
    
    # Adds a prefix onto the last nested segment of a long option.
    #
    #   prefix_long('--opt', 'no-')         # => '--no-opt'
    #   prefix_long('--nested:opt', 'no-')  # => '--nested:no-opt'
    #
    def prefix_long(switch, prefix, split_char=':')
      switch = switch[2, switch.length-2] if switch =~ /^--/
      switch = switch.split(split_char)
      switch[-1] = "#{prefix}#{switch[-1]}"
      "--#{switch.join(':')}"
    end
    
    # A wrapping algorithm slightly modified from:
    # http://blog.macromates.com/2006/wrapping-text-with-regular-expressions/
    def wrap(line, cols=80, tabsize=2)
      line = line.gsub(/\t/, " " * tabsize) unless tabsize == nil
      line.gsub(/(.{1,#{cols}})( +|$\r?\n?)|(.{1,#{cols}})/, "\\1\\3\n").split(/\s*?\n/)
    end
  end
end