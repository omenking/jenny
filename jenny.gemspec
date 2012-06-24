# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'admin_panel/version'

Gem::Specification.new do |s|
  s.name              = 'jenny'
  s.version           = Jenny::VERSION
  s.authors           = ['omenking']
  s.email             = ['omen.king@gmail.com']
  s.homepage          = ''
  s.summary           = %q{Useful helper methods for Rails views}
  s.description       = %q{Useful helper methods for Rails views}
  s.rubyforge_project = 'jenny'


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
