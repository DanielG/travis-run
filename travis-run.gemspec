# encoding: utf-8

Gem::Specification.new do |s|
  s.name         = 'travis-run'
  s.version      = '0.0.1'
  s.author       = "Daniel Gröber"
  s.email        = 'dxld@darkboxed.org'
  s.homepage     = 'http://github.com/DanielG/travis-run'
  s.summary      = '[summary]'
  s.description  = '[description]'
  s.files        = Dir['{lib/**/*,[A-Z]*,*.sh,travis-run,backends/*,docker/*,Gemfile}']
  s.executables << 'travis-run'
end
