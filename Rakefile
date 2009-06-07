# jwz_threading Rakefile
#
# 

require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rcov/rcovtask'
#require 'rake/gempackagetask'
require 'lib/jwz_threading/version'
require 'echoe'

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
 

Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'echoe'
 
  Echoe.new(PKG_NAME, PKG_VERSION) do |p|
    p.rubyforge_name = 'jwz_threading'
    p.summary      = JWZThreading::VERSION::SUMMARY
    p.description  = <<-EOF
      It is a small ruby library which lets you order a list of E-Mails by conversation.
      That is, grouping messages together in parent/child relationships based on which 
      messages are replies to which others.
    EOF
    p.url          = 'http://github.com/fdietz/jwz_threading'
    p.author       = 'Frederik Dietz'
    p.email        = "fdietz@gmail.com"
  end
 
rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
  puts "#{boom.to_s.capitalize}."
end
