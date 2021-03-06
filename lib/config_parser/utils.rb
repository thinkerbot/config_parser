class ConfigParser

  # A medly of methods used throughout the ConfigParser classes.
  module Utils
    module_function

    # The default option break
    OPTION_BREAK = "--"

    # Matches an option (long or short)
    OPTION = /\A-./

    # Matches a long flag
    LONG_FLAG = /\A--.+\z/

    # Matches a short flag
    SHORT_FLAG = /\A-.\z/

    # Matches a switch option (ex: '--[no-]opt', '--nest:[no-]opt'). After the
    # match:
    #   
    #   $1:: the nesting prefix ('nest')
    #   $2:: the negative long prefix ('no')
    #   $3:: the long flag name ('opt')
    #
    SWITCH = /\A--(.*?)\[(.*?)-\](.+)\z/

    # Matches a nest option (ex: '--nest:opt').  After the match:
    #
    #   $1:: the nesting prefix ('nest')
    #   $2:: the long option ('long')
    #
    NEST = /\A--(.*):(.+)\z/

    # The default split character for multiple values
    DELIMITER = ','

    # Turns the input into a short flag by prefixing '-' (as needed). Raises
    # an error if the input doesn't result in a short flag.   Nils are
    # returned directly.
    #
    #   shortify('-o')         # => '-o'
    #   shortify(:o)           # => '-o'
    #
    def shortify(str)
      return nil if str.nil?

      str = str.to_s
      str = "-#{str}" unless option?(str)

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
      return nil if str.nil?

      str = str.to_s
      str = "--#{str}" unless option?(str)

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

    # Returns true if the object is a string and matches OPTION.
    def option?(obj)
      obj.kind_of?(String) && obj =~ OPTION ? true : false
    end

    # Shifts and returns the first argument off of argv if it is an argument
    # (rather than an option) or returns the default value.
    def next_arg(argv)
      option?(argv.at(0)) ? nil : argv.shift
    end

    # A wrapping algorithm slightly modified from:
    # http://blog.macromates.com/2006/wrapping-text-with-regular-expressions/
    def wrap(line, cols=80, tabsize=2)
      line = line.gsub(/\t/, " " * tabsize) unless tabsize == nil
      line.gsub(/(.{1,#{cols}})( +|$\r?\n?)|(.{1,#{cols}})/, "\\1\\3\n").split(/\s*?\n/)
    end

    # Parses the argv into an attributes hash for initializing an option.
    # Heuristics are used to infer what an argument implies.
    #  
    #   Argument            Implies
    #   -s                  :short => '-s'
    #   --long              :long => '--long'
    #   --long ARG          :long => '--long', :arg_name => 'ARG'
    #   --[no-]long         :long => '--long', :prefix => 'no', :option_type => :switch
    #   --nest:long         :long => '--nest:long', :nest_keys => ['nest']
    #   'some string'       :desc => 'some string'
    #
    # Usually you overlay these patterns, for example:
    #
    #   -s ARG              :short => '-s', :arg_name => 'ARG'
    #   --nest:[no-]long    :long => '--nest:long', :nest_keys => ['nest'], :prefix => 'no', :option_type => :switch
    #
    # The goal of this method is to get things right most of the time, not to
    # be clean, simple, or robust.  Some errors in declarations (like an
    # arg_name with a switch) can be detected... others not so much.
    def parse_attrs(argv)
      attrs={}

      argv.each do |arg|
        unless option?(arg)
          attrs[:desc] = arg
          next
        end

        flag, arg_name = arg.split(/\s+/, 2)

        if flag =~ NEST
          attrs[:nest_keys] = $1.split(':')
        end

        if arg_name
          attrs[:arg_name] = arg_name
        end

        case flag
        when SWITCH
          attrs[:long] = "--#{$1}#{$3}"
          attrs[:prefix] = $2

          if arg_name
            raise ArgumentError, "arg_name specified for switch: #{arg_name}"
          end

        when LONG_FLAG
          attrs[:long] = flag

        when SHORT_FLAG
          attrs[:short] = flag

        else
          raise ArgumentError.new("invalid flag: #{arg.inspect}")
        end
      end

      attrs
    end

    # Guesses an option type based on the attrs.
    #
    #   if...            then...
    #   prefix      =>   :switch
    #   arg_name    =>   guess_option_type_by_arg_name || guess_option_type_by_value
    #   default     =>   (guess_option_type_by_value)
    #   all else    =>   :flag
    #
    # A guess is just a guess; for certainty specify the type manually.
    def guess_option_type(attrs)
      case
      when attrs.has_key?(:prefix)
        :switch
      when attrs.has_key?(:arg_name)
        guess_option_type_by_arg_name(attrs[:arg_name]) || guess_option_type_by_value(attrs[:default])
      when attrs.has_key?(:default)
        guess_option_type_by_value(attrs[:default])
      else
        :flag
      end
    end

    # Guesses :list if the arg_name has a comma, or nil.
    def guess_option_type_by_arg_name(arg_name)
      arg_name.to_s.include?(',') ? :list : nil
    end

    # Guesses an option type based on a value.
    #
    #   if...            then...
    #   true        =>   :switch
    #   false       =>   :flag
    #   Array       =>   :list
    #   all else    =>   :option
    #
    # A guess is just a guess; for certainty specify the type manually.
    def guess_option_type_by_value(value)
      case value
      when true  then :switch
      when false then :flag
      when Array then :list
      else :option
      end
    end

    def guess_hint(attrs)
      default = attrs[:default]

      case default
      when true, false, nil
        nil
      when Array
        hint = default.join(attrs[:delimiter] || DELIMITER)
        hint.empty? ? nil : hint
      else
        default.to_s
      end
    end
  end
end