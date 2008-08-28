require 'rubygems'
require 'tmail'

require 'lib/threading.rb'

class Main
  
  def parse_mailbox
    #mbox_file = File.dirname(__FILE__) + '/../test1.mbox'
    #mbox_file = 'example/test1.mbox'
    mbox_file = "/Volumes/DATA/#backup/gmail/backup 2008.mbox/mbox"
    mailbox = TMail::UNIXMbox.new(mbox_file, nil, true)
  end

  def main
    mailbox = parse_mailbox
    messages = {}
    mailbox.each_port do |port|
      mail = TMail::Mail.new(port)
        
      m = MessageFactory.create(mail.subject, mail.message_id, mail.references)
      m.from = mail.from
      messages[mail.message_id] = m
      #puts "parsed #{mail.subject}"
    end
    
    threading = Threading.new
    root = threading.thread(messages)
  
    debug = ThreadingDebug.new
    debug.print_tree(root)  
  end
  
end

Main.new.main


