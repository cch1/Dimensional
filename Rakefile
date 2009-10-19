require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rubygems'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end
Rake::Task['test'].comment = "Run all tests in test/*_test.rb"

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = %q{dimensional}
  s.version = "0.0.2"
  s.required_ruby_version = '>= 1.6.8'
  s.date = %q{2009-10-09}
  s.authors = ["Chris Hapgood"]
  s.email = %q{cch1@hapgoods.com}
  s.summary = %q{Dimensional provides handling for numbers with units.}
  s.homepage = %q{http://cho.hapgoods.com/dimensional}
  s.description = <<-EOF
    Dimensional provides handling for dimensional values (numbers with units).  Dimensional values
    can be parsed, stored, converted and formatted for output.
  EOF
  s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.files += ["README", "CHANGELOG", "LICENSE", "Rakefile"]
  s.test_files = Dir['test/**/*.rb']
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = false
end