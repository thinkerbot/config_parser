$:.unshift File.expand_path('../lib', __FILE__)
require 'config_parser/version'

Gem::Specification.new do |s|
  s.name = 'config_parser'
  s.version = ConfigParser::VERSION
  s.author = 'Simon Chiang'
  s.email = 'simon.a.chiang@gmail.com'
  s.homepage = ''
  s.platform = Gem::Platform::RUBY
  s.summary = ''
  s.require_path = 'lib'
  s.rubyforge_project = ''
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title Config\ Parser}
  
  s.add_dependency('lazydoc', '~> 1.0')
  # s.add_development_dependency('tap-test')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
    MIT-LICENSE
  }
  
  # list the files you want to include here.
  s.files = %W{
  }
end