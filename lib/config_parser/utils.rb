class ConfigParser
  
  # A medly of methods used throughout the ConfigParser classes.
  module Utils
    module_function
    
    # A format string used by to_s
    LINE_FORMAT = "%-36s %-43s"
    
    # Matches an option word.  Option words must start with a word character
    # and may contain any characters except = and whitespace.
    OPTWORD = /\w[^=\s]*?/
    
    # Matches both long and short option declarations (ex: '-o', '-o VALUE',
    # '--opt VALUE').  After the match:
    #
    #   $1:: the option name
    #   $2:: the option prefix ('-' or '--')
    #   $3:: the arg_name, if present
    #
    OPTION = /\A((-{1,2})#{OPTWORD})(?:[=\s]\s*(.*))?\z/
    
    # Matches switch declarations (ex: '--[no-]opt', '--nest:[no-]opt'). 
    # After the match:
    # 
    #   $1:: the nesting prefix ('nest')
    #   $2:: the negative prefix ('no')
    #   $3:: the long option name ('opt')
    #   $4:: the arg_name, if present
    #
    SWITCH = /\A--(?:(#{OPTWORD}):)?\[(#{OPTWORD})-\](#{OPTWORD})(?:[=\s]\s*(.*))?\z/
    
    # The option break argument
    OPTION_BREAK = "--"
    
    # Matches a nested long option, with or without a value (ex: '--opt',
    # '--nested:opt', '--opt=value').  After the match:
    #
    #   $1:: the switch
    #   $2:: the value
    #
    LONG_OPTION = /\A(--\w\S*?)(?:=(.*))?\z/

    # Matches a nested short option, with or without a value (ex: '-o',
    # '-n:o', '-o=value').  After the match:
    #
    #   $1:: the switch
    #   $2:: the value
    #
    SHORT_OPTION = /\A(-\w)(?:=(.*))?\z/

    # Matches the alternate syntax for short options (ex: '-n:ovalue',
    # '-ovalue').  After the match:
    #
    #   $1:: the switch
    #   $2:: the value
    #
    ALT_SHORT_OPTION = /\A(-\w)(.+)\z/
    
    # Turns the input string into a short-format option.  Raises an error if
    # the option does not match SHORT_OPTION.  Nils are returned directly.
    #
    #   shortify('-o')         # => '-o'
    #   shortify(:o)           # => '-o'
    #
    def shortify(str)
      return nil if str == nil
  
      str = str.to_s
      str = "-#{str}" unless str[0] == ?-
      unless str =~ SHORT_OPTION && $2 == nil
        raise ArgumentError, "invalid short option: #{str}"
      end
      str
    end

    # Turns the input string into a long-format option.  Underscores are
    # converted to hyphens. Raises an error if the option does not match
    # LONG_OPTION.  Nils are returned directly.
    #
    #   longify('--opt')       # => '--opt'
    #   longify(:opt)          # => '--opt'
    #   longify(:opt_ion)      # => '--opt-ion'
    #
    def longify(str)
      return nil if str == nil
  
      str = str.to_s
      str = "--#{str}" unless str =~ /^--/
      str.gsub!(/_/, '-')
      unless str =~ LONG_OPTION && $2 == nil
        raise ArgumentError, "invalid long option: #{str}"
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