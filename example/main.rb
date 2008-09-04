require 'rubygems'
require 'tmail'
require 'logging'
require 'lib/threading'
class Main
  
  #MBOX_FILE = "/Volumes/DATA/#backup/gmail/backup 2006.mbox/mbox"
  MBOX_FILE = File.join(File.dirname(__FILE__),"test1.mbox")

  def main     
    threading = MailHelper::Threading.new
    
    # create logger with log level "info"
    logger = Logging::Logger['MailHelper::Threading']
    #logger.level = :debug
    logger.add_appenders(
      Logging::Appender.stdout
      #Logging::Appenders::File.new('example.log')
    )
    
    logger.info "parsing mailbox... #{MBOX_FILE}"
    mailbox = TMail::UNIXMbox.new(MBOX_FILE, nil, true)
    
    logger.info "creating list of input mails"
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
  def self.print_tree(root)
    root.children.each do |container|
      print_container(container)   
      print_children(2, container.children)
    end
  end
  
  def self.print_children(indent, children)
    begin
      children.each do |container|
        indent.times {print " "}
        print_container container
        print_children(indent+2, container.children)
      end
    rescue Exception => e
      puts "Error: #{e.to_s}"
      puts e.backtrace
    end
  end
  
  def self.print_container(container)
    unless container.message == nil
      print "#{container.message.subject}:#{container.message.from}"
    else
      print "#{container.object_id} (dummy)"
    end
    unless container.children.size == 0
      print "(#{container.children.size})"
    end    
      print "\n"
  end
end


Main.new.main


