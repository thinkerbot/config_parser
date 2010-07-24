require 'config_parser/option'

class ConfigParser
  class List < Option
    SPLIT = ','
    
    attr_reader :limit
    attr_reader :split
    
    def initialize(attrs={})
      super
      @limit = attrs[:n]
      @split = attrs[:split] || SPLIT
    end
    
    def assign(config, value)
      return unless key
      array = (config[key] ||= [])
      array.concat(split ? value.split(split) : [value])
      
      if limit && array.length > limit
        raise "too many assignments: #{key.inspect}"
      end
      
      array
    end
  end
end