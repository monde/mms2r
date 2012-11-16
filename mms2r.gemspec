$:.unshift File.expand_path("../lib", __FILE__)
require "mms2r/version"

Gem::Specification.new do |gem|

  gem.add_dependency 'rake'
  gem.add_dependency 'nokogiri', ['>= 1.5.0']
  gem.add_dependency 'mail',     ['>= 2.4.0']
  gem.add_dependency 'exifr',    ['>= 1.0.3']
  gem.add_dependency 'json',     ['>= 1.6.0']

  gem.add_development_dependency "rdoc"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency 'test-unit'
  gem.add_development_dependency 'mocha'

  gem.name        = "mms2r"
  gem.version     =  MMS2R::Version.to_s
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Mike Mondragon"]
  gem.email       = ["mikemondragon@gmail.com"]
  gem.homepage    = "https://github.com/monde/mms2r"
  gem.summary     = "Extract user media from MMS (and not carrier cruft)"
  gem.description = "MMS2R is a library that decodes the parts of a MMS message to disk while stripping out advertising injected by the mobile carriers."
  gem.rubyforge_project = "mms2r"
  gem.rubygems_version = ">= 1.3.6"
  gem.files         = `git ls-files`.split("\n")
  gem.require_path  = ['lib']
  gem.rdoc_options = ["--main", "README.rdoc"]
  gem.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.TMail.txt", "README.rdoc"]

  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
end
