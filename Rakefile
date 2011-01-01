# -*- ruby -*-

begin
  require 'hoe'
rescue LoadError
  require 'rubygems'
  require 'hoe'
end

begin
  require 'rcov/rcovtask'
rescue LoadError
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "lib")
require 'mms2r'
require 'rake'

Hoe.plugin :bundler
Hoe.spec('mms2r') do |p|
  p.version        = MMS2R::Media::VERSION
  p.rubyforge_name = 'mms2r'
  p.author         = ['Mike Mondragon']
  p.email          = ['mikemondragon@gmail.com']
  p.summary        = 'Extract user media from MMS (and not carrier cruft)'
  p.description    = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url            = p.paragraphs_of('README.txt', 1).first.strip
  p.changes        = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.readme_file    = 'README.txt'
  p.history_file   = 'History.txt'
  p.extra_deps << ['nokogiri', '>= 1.4.4']
  p.extra_deps << ['mail', '>= 2.2.10']
  p.extra_deps << ['uuidtools', '>= 2.1.1']
  p.extra_deps << ['exifr', '>= 1.0.3']
  p.clean_globs << 'coverage'
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |rcov|
    rcov.pattern = 'test/**/test_*.rb'
    rcov.verbose = true
    rcov.rcov_opts << "--exclude rcov.rb"
  end
rescue
  task :rcov => :check_dependencies
end

# vim: syntax=Ruby
