require 'aspector/version'

Gem::Specification.new do |s|
  s.name = %q( aspector )
  s.version = Aspector::VERSION

  s.authors     = %q( Guoliang Cao )
  s.date        = %q( 2015-07-07 )
  s.email       = %q( gcao99@gmail.com )
  s.summary     = %q( Aspect Oriented Ruby Programming library )
  s.homepage    = %q( http://github.com/gcao/aspector )
  s.licenses    = %w( MIT )
  s.description = %q()
  s.rubygems_version = %q( 1.6.2 )

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = %w( lib )
end
