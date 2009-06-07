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
  s.homepage = 'http://github.com/fdietz/jwz_threading'
  s.platform = Gem::Platform::RUBY
  s.rubyforge_project = 'jwz_threading'
end
