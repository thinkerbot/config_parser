require 'rake'
require 'rake/rdoctask'

#
# Gem specification
#

def gemspec
  require 'rubygems/specification'
  path = File.expand_path('config_parser.gemspec')
  eval(File.read(path), binding, path, 0)
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
    next if file =~ /^(rdoc|pkg|test|.*\.rbc)/ || File.directory?(file)
    
    path = File.expand_path(file)
    files[path] = ['', file] unless files.has_key?(path)
  end
  
  # sort and output the results
  files.values.sort_by {|exists, file| file }.each do |entry| 
    puts '%-5s %s' % entry
  end
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
  output = `bundle check 2>&1`
  
  unless $?.to_i == 0
    puts output
    puts "bundle install 2>&1"
    system "bundle install 2>&1"
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

