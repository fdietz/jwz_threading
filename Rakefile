# jwz_threading Rakefile
#
# 

require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rcov/rcovtask'
require 'lib/jwz_threading/version'

DIR = File.dirname(__FILE__)

PKG_NAME = 'jwz_threading'
PKG_VERSION = JWZThreading::VERSION::STRING
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
PKG_FILES = FileList[
  '[A-Z]*',
  'lib/**/*.rb',
  'test/**/*',
]

CLOBBER.include 'doc'

task :default => 'test'
 
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end
  
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = File.join('doc', 'rdoc')
  rdoc.options << '--title' << 'jwz_threading' << '--line-numbers'
  rdoc.options << '--inline-source' << '--main' << 'README'
  rdoc.rdoc_files.include('README', 'CHANGELOG', 'MIT-LICENSE', 'lib/**/*.rb')
end