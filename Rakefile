require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'

#
# Gem specification
#

def gemspec
  require 'rubygems/specification'
  path = File.expand_path('config_parser.gemspec')
  eval(File.read(path), binding, path, 0)
end

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_tar = true
end

desc 'Prints the gemspec manifest.'
task :print_manifest do
  # collect files from the gemspec, labeling 
  # with true or false corresponding to the
  # file existing or not
  files = gemspec.files.inject({}) do |files, file|
    files[File.expand_path(file)] = [File.exists?(file), file]
    files
  end
  
  # gather non-rdoc/pkg files for the project
  # and add to the files list if they are not
  # included already (marking by the absence
  # of a label)
  Dir.glob('**/*').each do |file|
    next if file =~ /^(rdoc|pkg|backup|test|submodule|.*\.rbc)/ || File.directory?(file)
    
    path = File.expand_path(file)
    files[path] = ['', file] unless files.has_key?(path)
  end
  
  # sort and output the results
  files.values.sort_by {|exists, file| file }.each do |entry| 
    puts '%-5s %s' % entry
  end
end

desc 'Publish RDoc to RubyForge'
task :publish_rdoc => [:rdoc] do
  require 'yaml'
  
  config = YAML.load(File.read(File.expand_path('~/.rubyforge/user-config.yml')))
  host = "#{config['username']}@rubyforge.org"
  
  rsync_args = '-v -c -r'
  remote_dir = '/var/www/gforge-projects/tap/configurable'
  local_dir = 'rdoc'
 
  sh %{rsync #{rsync_args} #{local_dir}/ #{host}:#{remote_dir}}
end

#
# Documentation tasks
#

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  spec = gemspec
  
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options.concat spec.rdoc_options
  rdoc.rdoc_files.include( spec.extra_rdoc_files )
  rdoc.rdoc_files.include( spec.files.select {|file| file =~ /^lib.*\.rb$/} )
end

#
# Dependency tasks
#

desc 'Bundle dependencies'
task :bundle do
  opts = %w{prd acp qa tst}.include?(ENV['WCIS_ENV']) ? ' --without=development' : ''
  output = `bundle check 2>&1`
  
  unless $?.to_i == 0
    puts output
    stdout_sh "bundle install#{opts} 2>&1"
    puts
  end
end

#
# Test tasks
#

desc 'Default: Run tests.'
task :default => :test

desc 'Run the tests'
task :test => :bundle do
  tests = Dir.glob('test/**/*_test.rb')
  sh('ruby', '-w', '-e', 'ARGV.dup.each {|test| load test}', *tests)
end

desc 'Run the benchmarks'
task :benchmark => :bundle do
  benchmarks = Dir.glob('benchmark/**/*_benchmark.rb')
  sh('ruby', '-w', '-e', 'ARGV.dup.each {|benchmark| load benchmark}', *benchmarks)
end

