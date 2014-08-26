# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "snappler_contable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "snappler_contable"
  s.version     = SnapplerContable::VERSION
  s.authors     = ["Juan La Battaglia"]
  s.email       = ["juan.labattaglia@snappler.com"]
  s.homepage    = "www.snappler.com"
  s.summary     = "Agrega modelo contable a una aplicacion"
  s.description = "Agrega modelo contable a una aplicacion"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

end
