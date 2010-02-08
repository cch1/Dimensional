require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'jeweler'
require 'lib/dimensional/version'

spec = Gem::Specification.new do |spec|
  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  spec.platform = Gem::Platform::RUBY
  spec.name = %q{dimensional}
  spec.version = Dimensional::VERSION
  spec.required_ruby_version = '>= 1.6.8'
  spec.date = Time.now.strftime("%Y-%m-%d")
  spec.authors = ["Chris Hapgood"]
  spec.email = %q{cch1@hapgoods.com}
  spec.summary = %q{Dimensional provides handling for numbers with units.}
  spec.homepage = %q{http://cho.hapgoods.com/dimensional}
  spec.description = <<-EOF
    Dimensional provides handling for dimensional values (numbers with units).  Dimensional values
    can be parsed, stored, converted and formatted for output.
  EOF
  spec.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  spec.files += ["README", "CHANGELOG", "LICENSE", "Rakefile", "test/helper.rb"]
  spec.test_files = ["test/helper.rb"] + Dir['test/**/*_test.rb']
end

Jeweler::Tasks.new(spec)
Jeweler::GemcutterTasks.new

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end
Rake::Task['test'].comment = "Run all tests in test/*_test.rb"

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Dimensional #{version}"
  rdoc.rdoc_files.include(%w(README LICENSE CHANGELOG TODO))
  rdoc.rdoc_files.include('test/demo.rb')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :test => :check_dependencies
task :default => :test