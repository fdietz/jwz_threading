dir = File.dirname(__FILE__)
lib_path = File.expand_path(File.join(dir, '..', 'lib'))

#$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

require 'test/unit'
require 'rubygems'
require 'lib/threading'
require 'logging'

class Test::Unit::TestCase  
  # test "verify something" do
  #   ...
  # end
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end
