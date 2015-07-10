require 'aspector/version'

Gem::Specification.new do |s|
  s.name = 'aspector'
  s.version = Aspector::VERSION

  s.authors     = ['Guoliang Cao', 'Maciej Mensfeld']
  s.date        = %w( 2015-07-07 )
  s.email       = ['gcao99@gmail.com', 'maciej@mensfeld.pl']
  s.summary     = %w( Aspect Oriented Ruby Programming library )
  s.homepage    = 'http://github.com/gcao/aspector'
  s.licenses    = %w( MIT )
  s.description = %w()
  s.rubygems_version = %w( 1.6.2 )

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = %w( lib )
end
