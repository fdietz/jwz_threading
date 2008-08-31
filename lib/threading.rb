#!/user/bin/ruby
  
require 'rubygems'
require 'breakpoint'
require 'uuid'
require 'logger'
require 'lib/threading_debug'
require 'lib/message_parser'


# Container for creation of parent/child relationship of messages 
class Container
  attr_accessor :parent, :children, :next, :message
  
  def initialize()
    @parent = nil
    @message = nil
    @children = []
    @next = nil
  end
  
  def is_dummy
    @message.nil?
  end
  
  def add_child(child)
    if not child.parent.nil?
      child.parent.remove_child(child)
    end
    
    @children << child
    child.parent = self
  end
  
  def remove_child(child)
    @children.delete(child)
    child.parent = nil
  end
  
  def has_descendant(container, level = 0)
    if self == container
      return true
    end
     
    if @children.size == 0 
      return false
    end
    
    level = level + 1
    @children.each do |c|
      if c == container 
        return true
      elsif c.has_descendant(container, level)
        return true
      end    
    end
   false
  end
end

# Lightweight Message for the minimal used message attributes
class Message
  attr_reader :subject, :message_id, :references
  attr_accessor :from
  
  def initialize(subject, message_id, references)
    @subject = subject;
    @message_id = message_id
    @references = references
    @from = ""
  end
end

# Factory for creating messages. Ensures consistent data required
# for threading algorithm.
class MessageFactory
  
  def self.create(subject, message_id, in_reply_to, references)
    
    references = [] if references.nil?
    in_reply_to = [] if in_reply_to.nil?
    
    # if there are no message-IDs in references header  
    if references.size == 0 
        # use the first found message-ID of the in-reply-to header instead
        if in_reply_to.size > 0
          references << in_reply_to[0]
        end
    end
    
    if subject.nil?
      subject = ""
    end
    
    if message_id.nil?
      message_id = UUID.new +  "@fdietz"
    end
    
    Message.new(subject, message_id, references)
  end
  
end


#
# Threading takes a list of RFC822 compliant emails and orders
# them by conversation. That is, grouping messages together in 
# parent/child relationships based on which messages are replies 
# to which others.
# It implements the JWZ E-Mail threading algorithm as described 
# by Jamie Zawinski (http://www.jwz.org/doc/threading.html).
#
# Example usage:
#  # use TMail or other library to create messages
#  mail = TMail::Mail.parse("From mikel@example.org\nReceived by.... etc")
#  # .. go on creating emails
#
#  # create hash of messages 
#  # key = message_id, value = message
#  messages = {}
# 
#  # store each email created above in hash
#  # -> create lightweight message object
#  light_mail = MessageFactory.create(mail.subject, mail.message_id, mail.in_reply_to, mail.references)
#  messages[light_mail.message_id] = light_mail
#  # .. go on for each created email 
#
#  root_node = Threading.new.thread(messages)
#
# Logging output can be configured in the following way:
#
#  logger = Logging::Logger['Threading']
#  logger.level = :info
#  logger.add_appenders(
#    Logging::Appender.stdout
#    #Logging::Appenders::File.new('example.log')
#  )
# 
class Threading

  # Init logger
  def initialize
    @logger = Logging::Logger[self]
    @logger.level = :info
    @logger.add_appenders(
      Logging::Appender.stdout
      #Logging::Appenders::File.new('example.log')
    )
  end
  
  # Execute the threading algorithm
   # 
   # TODO: re-enable grouping by subject
   #
   def thread(messages)
     @logger.info "jwz threading algorithm executing"

     # create id_table
     id_table = create_id_table(messages)

     # create root hierachy siblings out of containers with zero children
     root = create_root_hierachy_2(id_table);

     # discard id_table
     id_table = nil

     # prune dummy containers
     prune_empty_containers(root)

     # group again this time use Subject only
     #subject_table = group_root_set_by_subject(root)

     root
   end
  
  # create container for each message
  def create_container_1A(id_table, message_id, message)
    @logger.info "1A create container for each message"
    parent_container = nil
    # if id_table contains empty container for message id
    if id_table.has_key?(message_id)
      # store this message in container's message slot
      parent_container = id_table[message_id]
      parent_container.message = message
      @logger.debug "1A found existing container for #{message_id}"
    else
      parent_container = Container.new()
      parent_container.message = message
      id_table[message_id] = parent_container
      @logger.debug "1A created new container for #{message_id}"
    end
    parent_container
  end

  # create hierachy of message containers based on references and message-IDs
  def create_hierachy_1B(id_table, message, parent_container)
    @logger.info "1B create hierachy of containers"
    prev = nil  
    message.references.each do |reference_id|
      @logger.debug "- 1B check reference id #{reference_id}"
      message_id = nil
      ref_container = nil
      # check if a container already exists
      if id_table.has_key?(reference_id)
        ref_container = id_table[reference_id]
        @logger.debug "- 1B found existing container for reference #{reference_id}"
      else
        # create new container with null message
        #message_id = UUID.new 
        ref_container = Container.new()
        id_table[reference_id] = ref_container
        @logger.debug "- 1B created new container for #{reference_id}"
      end
    
      if ( prev != nil)
        # don't create a loop
        if ref_container == parent_container
          @logger.debug "- 1B ref_container == parent_container -> skip since we don't want create a loop!"
          next
        end
        #if prev.has_descendant(ref_container)
        if ref_container.has_descendant(prev)
         @logger.debug "- 1B ref_container already has descendants!"
          next
        end
      
        prev.add_child(ref_container)
        @logger.debug "- 1B added ref_container to prev"
      end

      
      prev = ref_container
      @logger.debug "- 1B prev = ref_container"
    end    
  
    if ( prev != nil)
      @logger.debug "- 1B added parent_container to prev"
      prev.add_child(parent_container)
    end
  end
  
  # create root hierachy by using all containers with no parent
  def create_root_hierachy_2(id_table)
    @logger.info "create root hierachy for all containers with no parent"
    root = Container.new()
    id_table.each_pair do |message_id, container|
      if container.parent == nil
        root.add_child(container)
      end
    end
    root
  end
  
  # create hash 
  # key = message_id, value = message
  def create_id_table(messages)
    @logger.info "create id_table hash"
    id_table = Hash.new
    messages.each_pair do |message_id, message|
    
      #puts "create container 1A"
      
      # 1A
      # create container for each message or use existing one
      parent_container = create_container_1A(id_table, message_id, message)
      
      #puts "create hierachy 1B"
      
      # 1B
      # for each element in the message's references field find a container  
      create_hierachy_1B(id_table, message, parent_container)
    end  
    id_table
  end
  
 
  
  # recursively traverse all containers under root and remove dummy containers
  def prune_empty_containers(parent)
   @logger.info "prune empty containers"
    
    parent.children.reverse_each do |container|
      #for container in parent.children
      @logger.debug "traversing #{container.object_id}"
     
    
      # recursively do the same
      prune_empty_containers(container)
      
      # If it is a dummy message with NO children, delete it.
      if container.message.nil? && container.children.empty?
        # delete container
        parent.remove_child(container)
        @logger.debug "#{container.object_id }:remove dummy with no children #{container.object_id}"

      # If it is a dummy message with children, delete it  
      elsif container.message.nil? #&& ( not container.children.empty? )
        
        # Do not promote the children if doing so would make them
        # children of the root, unless there is only one child.
        if parent.parent.nil? && container.children.size == 1
          # promote its children to current level 
          container.children.reverse_each {|c| parent.add_child(c) } 
          @logger.debug "#{container.object_id }:promote children to current level #{container.children.size}"
          parent.remove_child(container)

        elsif parent.parent.nil? && container.children.size > 1
          # do not promote its children
          @logger.debug "#{container.object_id }:do not promote children"
        else
          # promote its children to current level  
          container.children.reverse_each {|c| parent.add_child(c) } 
          
          @logger.debug "#{container.object_id }: promote children to current level #{container.children.size}"

          parent.remove_child(container)          
        end
      end
    end 
  end
    
  
  # group root set by subject
  def group_root_set_by_subject(root)
    @logger.info "group root set by subject"
    
    subject_table = {}
    
    # 5B
    # Populate the subject table with one message per each
    # base subject.  For each child of the root:
    root.children.each do |container|

      # Find the subject of this thread, by using the base
      # subject from either the current message or its first
      # child if the current message is a dummy.  This is the
      # thread subject.
      c = nil
      if container.message == nil
        c = container.children[0]
      else
        c = container
      end
      
      message = c.message
      if message.nil?
        next
      end
      
      subject = MessageParser.normalize_subject(message.subject)

      # If the thread subject is empty, skip this message
      if subject.length == 0 
        next
      end

      existing = subject_table[subject]
      
      # If there is no message in the subject table with the
      # thread subject, add the current message and the thread
      # subject to the subject table.
      if existing == nil
        subject_table[subject] = c
        
      # Otherwise, if the message in the subject table is not a
      # dummy, AND either of the following criteria are true:
      # - The current message is a dummy, OR
      # - The message in the subject table is a reply or forward
      #   and the current message is not.  
      elsif ( ( not existing.is_dummy) && ( c.is_dummy || ( 
        ( MessageParser.is_reply_or_forward existing.message.subject ) && 
        ( not MessageParser.is_reply_or_forward message.subject ))))
        subject_table[subject] = c
      end
      
    end
    
    # 5C
    # using reverse_each here because removing children from root
    # would lead to skipping of root's children
    root.children.reverse_each do |container|
      subject = nil
      
      # Find the subject of this thread, by using the base
      # subject from either the current message or its first
      # child if the current message is a dummy.  This is the
      # thread subject.
      if container.message == nil
        subject = container.children[0].message.subject
      else
        subject = container.message.subject
      end
      
      subject = MessageParser.normalize_subject(subject)
      
      c = subject_table[subject]
      
      # If the message in the subject table is the current
      # message, skip this message.
      if c == nil || c == container
       # puts ">>>> skip"
        next
      end
      
      
      
      # If both messages are dummies, append the current
      # message's children to the children of the message in
      # the subject table (the children of both messages
      # become siblings), and then delete the current message              
      if c.is_dummy() && container.is_dummy()
        container.children.each {|ctr| c.add_child(ctr) }
        container.parent.remove_child(container)
      # If the message in the subject table is a dummy and the
      # current message is not, make the current message a
      # child of the message in the subject table (a sibling
      # of its children).  
      elsif c.is_dummy() && ( not container.is_dummy() )
          c.add_child(container)
      # If the current message is a reply or forward and the
      # message in the subject table is not, make the current
      # message a child of the message in the subject table (a
      # sibling of its children).            
      elsif not MessageParser.is_reply_or_forward(c.message.subject) && 
        MessageParser.is_reply_or_forward(container.message.subject)
        c.add_child(container)     
      # Otherwise, create a new dummy message and make both
      # the current message and the message in the subject
      # table children of the dummy.  Then replace the message
      # in the subject table with the dummy message.
      else
        new_container = Container.new
        new_container.add_child(c)
        new_container.add_child(container)
        subject_table[subject] = new_container
      end    
    end

    subject_table
  end 
end
 