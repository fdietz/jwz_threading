require 'rubygems'
require 'tmail'
require 'lib/threading'

class Main
  
  MBOX_FILE = File.join(File.dirname(__FILE__),"test1.mbox")

  def main     
    threading = MailHelper::Threading.new
    
    mailbox = TMail::UNIXMbox.new(MBOX_FILE, nil, true)
    
    messages = []
    counter = 0
    mailbox.each_port do |port|
      mail = TMail::Mail.new(port)
        
      m = MailHelper::MessageFactory.create(mail.subject, mail.message_id, mail.in_reply_to, mail.references)
      m.from = mail.from
      messages << m
      counter += 1
      puts "#{counter}"
    end
  
    root = threading.thread(messages)
     
    PrettyPrinter.print_tree(root)
  end
end

class PrettyPrinter
  INDENT = 2
  def self.print_tree(root)
    root.children.each do |container|
      puts container
      print_children(INDENT, container.children)
    end
  end
  
  def self.print_children(indent, children)
    begin
      children.each do |container|
        indent.times { print " " }
        puts container
        print_children(indent+INDENT, container.children)
      end
    rescue Exception => e
      puts "Error: #{e.to_s}"
      puts e.backtrace
    end
  end
end


Main.new.main


