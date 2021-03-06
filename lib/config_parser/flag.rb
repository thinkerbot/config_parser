require 'config_parser/utils'

class ConfigParser

  # Represents a boolean flag-style option. Flag handles the parsing of
  # specific flags, and provides hooks for processing the various types of
  # options (Switch, Option, List).
  class Flag
    include Utils

    # The config key.
    attr_reader :key

    # The config nesting keys.
    attr_reader :nest_keys

    # The default value.
    attr_reader :default

    # The short flag mapping to self.
    attr_reader :short 

    # The long flag mapping to self.
    attr_reader :long

    # The description printed by to_s.
    attr_reader :desc

    # A hint printed by to_s, after desc.
    attr_reader :hint

    # A callback for processing values (must respond to call, or be nil).
    attr_reader :callback

    # A tracking flag set to true when assign is called.  Useful when assign
    # works differently for the first assignment than later assignments.  See
    # reset.
    attr_reader :assigned

    def initialize(attrs={})
      @key       = attrs[:key]
      @nest_keys = attrs[:nest_keys]
      @default   = attrs[:default]
      @short     = shortify(attrs.has_key?(:short) ? attrs[:short] : default_short)
      @long      = longify(attrs.has_key?(:long) ? attrs[:long] : default_long)
      @desc      = attrs[:desc]
      @hint      = attrs[:hint]
      @callback  = attrs[:callback]
      reset
    end

    # Returns an array of flags mapping to self (ie [long, short]).
    def flags
      [long, short].compact
    end

    # Parse handles the parsing of flags, which happens in three steps:
    #
    # * determine the value (occurs in parse)
    # * process the value
    # * assign the result into config
    #
    # Flag uses !default as the value (such that the flag indicates true if
    # the default is false) then passes the value to process, and then assign.
    # Raises and error if provided a value directly (flags always determine
    # their value based on the default).
    #
    #--
    # Implementation Note
    #
    # The compact syntax for short flags is handled through parse by
    # unshifting remaining shorts (ie value) back onto argv.  This allows
    # shorts that consume a value to take the remainder as needed.  As an
    # example to clarify, assume -x -y are flags where -x takes a value and -y
    # does not.  These are equivalent:
    #
    #   -x value -y
    #   -xvalue -y
    #   -y -xvalue
    #   -yxvalue
    #         
    # Whereas this is not:
    #
    #   -xyvalue                   # x receives 'yvalue' not 'value'
    #
    # Parse handles the compact short syntax splitting '-yxvalue' into '-y',
    # 'xvalue'. Then '-y' determines whether or not it needs a values; if not
    # '-xvalue' gets unshifted to argv and parsing continues as if '-y
    # -xvalue' were the original arguments.
    def parse(flag, value=nil, argv=[], config={})
      unless value.nil?
        if flag == short
          argv.unshift "-#{value}"
        else
          raise "value specified for #{flag}: #{value.inspect}"
        end
      end

      value = (default.nil? ? true : !default)
      assign(config, process(value))
    end

    # Process the value by calling the callback, if specified, with the value
    # and returns the result.  Returns value if no callback is specified.
    def process(value)
      callback ? callback.call(value) : value
    end

    # Assigns the default value into config and resets the assigned flag to
    # false, such that the next assign behaves as if self has not put a value
    # into config.  Returns config.
    def assign_default(config)
      assign(config, default)
      reset
      config
    end

    # Assign the value to the config hash, if key is set, and flips assigned
    # to true.  Returns config.
    def assign(config, value)
      if key
        nest_config = nest(config)
        nest_config[key] = value
      end

      @assigned = true
      config
    end

    # Returns the nested config hash for config, as specified by nest_keys.
    def nest(config)
      nest_keys.each do |key|
        config = (config[key] ||= {})
      end if nest_keys

      config
    end

    # Resets assigned to false.
    def reset
      @assigned = false
    end

    # Formats self as a help string for use on the command line (deprecated
    # for that use, see format instead).
    def to_s(opts={})
      width     = opts[:width] || 80
      head_size = opts[:head_size] || (width * 0.45).to_i
      desc_size = width - head_size - 1

      format = "%-#{head_size}s %-#{desc_size}s"

      lines  = wrap(desc_str, desc_size)

      header = header_str
      header = header.length > head_size ? header.ljust(width) : (format % [header, lines.shift])

      if lines.empty?
        header
      else
        lines.collect! {|line| format % [nil, line] }
        "#{header}\n#{lines.join("\n")}"
      end
    end

    # Returns an inspect string.
    def inspect
      "#<#{self.class}:#{object_id} key=#{key.inspect} default=#{default.inspect} long=#{long.inspect} short=#{short.inspect}>"
    end

    private

    def header_str # :nodoc:
      "    #{short_str}#{long_str}"
    end

    def short_str # :nodoc:
      case
      when short && long then "#{short}, "
      when short then "#{short}"
      else '    '
      end
    end

    def long_str # :nodoc:
      long
    end

    def desc_str # :nodoc:
      case
      when hint.nil? && desc.nil?
        ''
      when hint.nil? 
        desc.to_s
      else
        "#{desc} (#{hint})".strip
      end
    end

    def default_long # :nodoc:
      return nil if default_short
      nest_keys ? (nest_keys + [key]).join(':') : key
    end

    def default_short # :nodoc:
      key.to_s.length == 1 && nest_keys.nil? ? key : nil
    end
  end
end