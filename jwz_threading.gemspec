# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{jwz_threading}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Frederik Dietz"]
  s.date = %q{2009-06-07}
  s.description = %q{It is a small ruby library which lets you order a list of E-Mails by conversation. That is, grouping messages together in parent/child relationships based on which  messages are replies to which others.}
  s.email = %q{fdietz@gmail.com}
  s.extra_rdoc_files = ["CHANGELOG", "lib/jwz_threading/version.rb", "lib/threading.rb", "README"]
  s.files = ["CHANGELOG", "example/main.rb", "example/test1.mbox", "jwz_threading.gemspec", "lib/jwz_threading/version.rb", "lib/threading.rb", "MIT-LICENSE", "Rakefile", "README", "setup.rb", "test/message_parser_test.rb", "test/test_helper.rb", "test/threading_test.rb", "Manifest"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/fdietz/jwz_threading}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Jwz_threading", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{jwz_threading}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{jwz_threading version 0.2.0}
  s.test_files = ["test/message_parser_test.rb", "test/test_helper.rb", "test/threading_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
