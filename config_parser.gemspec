# -*- encoding: utf-8 -*-
require File.expand_path('../lib/config_parser/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'config_parser'
  s.version = ConfigParser::VERSION
  s.author = 'Simon Chiang'
  s.email = 'simon.a.chiang@gmail.com'
  s.homepage = ''
  s.platform = Gem::Platform::RUBY
  s.summary = 'Parse command-line options into a configuration hash'
  s.require_path = 'lib'
  s.rubyforge_project = ''
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title ConfigParser}
  
  # dependencies
  s.add_development_dependency('bundler', '~> 1.0')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
    MIT-LICENSE
  }
  
  # list the files you want to include here.
  s.files = %W{
    lib/config_parser.rb
    lib/config_parser/flag.rb
    lib/config_parser/list.rb
    lib/config_parser/option.rb
    lib/config_parser/switch.rb
    lib/config_parser/utils.rb
    lib/config_parser/version.rb
  }
end