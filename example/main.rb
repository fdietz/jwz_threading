require 'rubygems'
require 'tmail'
require 'logging'
require 'lib/threading.rb'

class Main
  
  #MBOX_FILE = "/Volumes/DATA/#backup/gmail/backup 2008.mbox/mbox"
  MBOX_FILE = File.join(File.dirname(__FILE__),"test1.mbox")

  def main
    # create logger with log level "info"
    logger = Logging::Logger['Threading']
    logger.level = :info
    logger.add_appenders(
      Logging::Appender.stdout
      #Logging::Appenders::File.new('example.log')
    )
         
    logger.info "parsing maibox... #{MBOX_FILE}"
    mailbox = TMail::UNIXMbox.new(MBOX_FILE, nil, true)
    
    logger.info "creating list of input mails"
    messages = {}
    mailbox.each_port do |port|
      mail = TMail::Mail.new(port)
        
      m = MessageFactory.create(mail.subject, mail.message_id, mail.in_reply_to, mail.references)
      m.from = mail.from
      messages[mail.message_id] = m
    end
  
    threading = Threading.new
    root = threading.thread(messages)
     
    debug = ThreadingDebug.new
    debug.print_tree(root)  
  end
  
end

Main.new.main


