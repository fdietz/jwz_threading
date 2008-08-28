#!/user/bin/ruby

require 'lib/message_parser.rb'
#require 'MessageParser'
require 'yaml'
require 'rubygems'
require 'breakpoint'
require 'logger'
require 'lib/threading_debug.rb'

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
    
    counter = 0
    @children.each do |c|
      counter += 1
    end
    
    puts "add_child: #{self.object_id}:##{counter}"
    
    @children << child
    child.parent = self
  end
  
  def remove_child(child)
    @children.delete(child)
    child.parent = nil
  end
  
  def has_descendant(container, level = 0)
    #puts "has_descendant: #{self.object_id}:#{container.children.size}:#{level}"
    if self == container
      return true
    end
     
    #puts "- has_descendant: #{self.object_id}:#{container.children.size}:#{level}"
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


class Message
  attr_accessor :subject, :message_id, :references
  attr_accessor :from
  
  def initialize(subject, message_id, references)
    @subject = subject;
    @message_id = message_id
    @references = references
    @from = ""
  end
end

class MessageFactory
  
  def self.create(subject, message_id, references)
    if references.nil?
      references = ""
    end
    
    Message.new(subject, message_id, references)
  end
  
end

class Threading

  def initialize
    #@logger = Logger.new($stderr)
    @logger = Logger.new('log/logfile.log')
    @logger.level = Logger::DEBUG
    @logger.datetime_format = '%H:%M:%S'
  end
  
  def create_container_1A(id_table, message_id, message)
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

  def create_hierachy_1B(id_table, message, parent_container)
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
        if prev.has_descendant(ref_container)
        #if ref_container.has_descendant(prev)
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
  
  def create_root_hierachy_2(id_table)
    @logger.debug "create root hierachy for all containers with no parent"
    root = Container.new()
    id_table.each_pair do |message_id, container|
      if container.parent == nil
        root.add_child(container)
      end
    end
    root
  end
  
  
  def create_id_table(messages)
    id_table = Hash.new
    messages.each_pair do |message_id, message|
    
      # 1A
      # create container for each message or use existing one
      parent_container = create_container_1A(id_table, message_id, message)
      
      # 1B
      # for each element in the message's references field find a container  
      create_hierachy_1B(id_table, message, parent_container)
    end  
    id_table
  end
  
  # recursively traverse all containers under root
  # for each container
  #  if it is an empty container
  #    -> delete container
  #  if container has no message, but does have children
  #    -> promote its children to this level 
  #       (do not promote them to root level, unless there is only one child) 
  def prune_empty_containers(root)
    root.children.each do |container|
      if container.message == nil && container.children.empty?
        # delete container
        container.parent.remove_child(container)
      elsif container.message == nil && !container.children.empty?
        # promote its children to this level 
        if container.parent == nil && container.children.size == 1
          children = container.children
          parent = container.parent
          container.parent.remove_child(container)
          children.each {|c| parent.add_child(c) } 
        else
          children = container.children
          parent = container.parent
          container.parent.remove_child(container)
          children.each {|c| parent.add_child(c) } 
        end
      end
      prune_empty_containers(container)
    end
  end
  
  def thread(messages)
    # create id_table
    id_table = create_id_table(messages)
    
    # create root hierachy siblings out of containers with zero children
    root = create_root_hierachy_2(id_table);
    
    # discard id_table
    id_table = nil
    
    prune_empty_containers(root)
    
    subject_table = group_root_set_by_subject(root)

    root
  end
  
  def group_root_set_by_subject(root)
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

      subject = MessageParser.new.normalize_subject(message.subject)

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
        ( MessageParser.new.is_reply_or_forward existing.message.subject ) && 
        ( not MessageParser.new.is_reply_or_forward message.subject ))))
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
      
      subject = MessageParser.new.normalize_subject(subject)
      
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
      elsif not MessageParser.new.is_reply_or_forward(c.message.subject) && 
        MessageParser.new.is_reply_or_forward(container.message.subject)
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
 