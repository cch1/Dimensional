#http://weblog.rubyonrails.org/2009/9/1/gem-packaging-best-practices

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = %q{dimensional}
  s.version = "0.0.0"
  s.required_ruby_version = '>= 1.6.8'
  s.date = %q{2009-10-09}
  s.authors = ["Chris Hapgood"]
  s.email = %q{cch1@hapgoods.com}
  s.summary = %q{Dimensional provides handling for dimensional values (numbers with units).}
  s.homepage = %q{http://cho.hapgoods.com/dimensional}
  s.description = <<-EOF
    Dimensional provides handling for dimensional values (numbers with units).  Dimensional values can be parsed, 
    stored, converted and formatted for output.
  EOF
  s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.files << ["README", "CHANGELOG", "LICENSE", "Rakefile"]
  s.test_files = Dir['test/**/*.rb']
end