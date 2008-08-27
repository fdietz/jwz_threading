#!/user/bin/ruby

class ThreadingDebug 
  
  def print_children(indent, children)
    begin
      children.each do |child|
        indent.times {print " "}
        unless child.is_dummy
          print "+- #{child.message.message_id}:#{child.message.subject}" 
          unless child.children.size == 0 
            print "(#{child.children.size}) \n"
          else
            print "\n"
          end
        else
          print "+- #{child.message.message_id} (dummy)"
          print "\n"
        end
        print_children(indent+2, child.children)
      end
    rescue Exception => e
      puts "Error: #{e.to_s}"
      puts e.backtrace
    end
  end

  def print_hash(id_table)
    puts "\n print_hash"
    puts "------------"
    id_table.each_pair do |message_id, container|
      print "#{container.message.message_id}:#{container.message.subject}" 
      unless container.children.size == 0 
        print "(#{container.children.size}) \n"
      else
        print "\n"
      end  
      #puts "--> child count #{container.children.size}"
      print_children(2, container.children)
    end
  end
  
  def print_tree(root)
    puts "\n print_tree"
    puts "------------"
    root.children.each do |container|
      unless container.message == nil
        print "#{container.message.message_id}:#{container.message.subject}"
      else
        print "#{container.message.message_id}"
      end
      
      unless container.children.size == 0
        print "(#{container.children.size}) \n"
      else
        print "\n"
      end   
      #puts "--> child count #{container.children.size}"
      print_children(2, container.children)
    end
  end
  
  def print_subject_hash(subject_hash)
    puts "\n print_subject_hash"
    puts "------------"
    
    subject_hash.each_pair do |subject, container|
      if container.message == nil 
        puts "#{subject}:#{container.to_s}"
      else
        puts "#{subject}:#{container.message.message_id}"
      end
      
    end
  end
end