# jwz_threading Rakefile
#
# 
$LOAD_PATH.unshift 'lib'

require 'rubygems'
require 'rake/gempackagetask'
#require 'rake/contrib/rubyforgepublisher'
require 'rake/clean'
require 'rake/rdoctask'
#require 'rake/testtask'
require 'spec/rake/spectask'
require 'jwz_threading/version'


DIR = File.dirname(__FILE__)

PKG_NAME = 'jwz_threading'
PKG_VERSION = JWZThreading::VERSION::STRING
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
PKG_FILES = FileList[
  '[A-Z]*',
  'lib/**/*.rb',
  'spec/**/*',
]

CLOBBER.include 'doc'

task :default => [ :spec ]

desc 'Run all specs'
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/*_spec.rb']
  t.warning = true
  t.rcov = true
  t.rcov_dir = File.join('doc', 'rcov')
end

desc 'Run all specs and store html output in doc/output/index.html'
Spec::Rake::SpecTask.new('spec_html') do |t|
  # create directory for documentation
  FileUtils.makedirs(File.join(DIR, 'doc', 'spec'))
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = [ '--format html:doc/spec/index.html',
                  '--format progress',
                  '--backtrace' ]
end

desc 'Generate RDoc'
rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = File.join('doc', 'rdoc')
  rdoc.options << '--title' << 'jwz_threading' << '--line-numbers'
  rdoc.options << '--inline-source' << '--main' << 'README'
  rdoc.rdoc_files.include('README', 'CHANGELOG', 'MIT-LICENSE', 'lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = JWZThreading::VERSION::SUMMARY
  s.description = <<-EOF
    It is a small ruby library which lets you order a list of E-Mails by conversation.
    That is, grouping messages together in parent/child relationships based on which 
    messages are replies to which others.
  EOF

  s.files = PKG_FILES.to_a
  s.require_path = 'lib'

  s.has_rdoc = true
  s.rdoc_options = rd.options
  s.extra_rdoc_files = rd.rdoc_files.reject {|fn| fn =~ /\.rb$/ }.to_a

  s.author = 'Frederik Dietz'
  s.email = 'fdietz@gmail.com'
  #s.homepage = 'http://jwzthreading.rubyforge.org'
  s.homepage = 'http://fdietz.wordpress.com'
  s.platform = Gem::Platform::RUBY
  s.rubyforge_project = 'jwz_threading'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end
