spec = Gem::Specification.new do |s|
  s.name         = 'suck'
  s.version      = '1.0.2'
  s.summary      = 'A really bad HTTP client wrapper'
  s.description  = "Please don't use this, there must be better HTTP clients around"
  s.files        = Dir['lib/**/*.rb']
  s.require_path = 'lib'
  s.autorequire  = 'suck'
  s.author       = 'Matt Mower'
  s.email        = 'self@mattmower.com'
  s.homepage     = 'http://github.com/mmower/suck'
end
