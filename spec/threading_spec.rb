require File.join(File.dirname(__FILE__), 'spec_helper')


describe "JWZ threading algorithm" do
  
  def path_helper(file)
    File.dirname(__FILE__) + file
  end
  
  # create message hash of yaml file
  # hash key is message_id
  # hash value the message with subject, message and references attributes
  class Parser
    def parse_inbox(path)
      yaml = File.open(path) {|f| YAML.load(f)}

      messages = Hash.new
      yaml.each do |key, value|
        ref = value["references"]
        if !ref 
          ref = []
        end   
        m = Message.new(value["subject"], key, ref)
        messages[key] = m
      end

      messages
    end
  end
  
  def parse_messages(file)
    parser = Parser.new
    messages = parser.parse_inbox path_helper("/#{file}")
  end
  
  before(:each) do
    @thread = Threading.new
    @debug = ThreadingDebug.new
    @message_parser = MessageParser.new
  end
  
  it "should create valid message by using references field" do
    message = MessageFactory.create("subject", "message_id", ["a"], ["a", "c"])
    message.references.should == ["a", "c"]
  end
  
  it "should create valid message by using in-reply-to field" do
    message = MessageFactory.create("subject", "message_id", ["a"], nil)
    message.references.should == ["a"]
  end
  
  it "should create valid message by using in-reply-to field with multiple message-IDs" do
    message = MessageFactory.create("subject", "message_id", ["a", "c"], nil)
    message.references.should == ["a"]
  end
  
  it "should create new container" do
    id_table = Hash.new
    message_a = Message.new("subject", "a", "")
    message_b = Message.new("subject", "b", "a")
    container_a = Container.new
    container_a.message = message_a
    container_b = Container.new
    container_b.message = message_b
    id_table["a"] = container_a
    
    parent_container = @thread.create_container_1A(id_table, message_b.message_id, message_b)
    
    id_table.should have(2).items
    id_table["b"].message.message_id.should == "b"
    id_table["b"].message.message_id.should == "b"
    
    id_table["b"].should == parent_container
  end
  
  it "should *not* create new container since equal container exists already" do
    id_table = Hash.new
    message_a = Message.new("subject", "a", "")
    message_b = Message.new("subject", "b", "a")
    container_a = Container.new
    container_a.message = message_a
    container_b = Container.new
    container_b.message = message_b
    id_table["a"] = container_a
    id_table["b"] = container_b
    
    parent_container = @thread.create_container_1A(id_table, message_b.message_id, message_b)
    id_table.should have(2).items
    id_table["b"].should == parent_container
  end
  
  it "should create id_table for each message" do
    messages = Hash.new
    messages["a"] = Message.new("subject", "a", "")
    messages["b"] = Message.new("subject", "b", "a")
    messages["c"] = Message.new("subject", "c", ["a", "b"])
    messages["d"] = Message.new("subject", "d", ["a", "b", "c"])
    messages["e"] = Message.new("subject", "e", "d")
 
    id_table = @thread.create_id_table(messages)
    
    #@debug.print_hash(id_table)
    
    id_table.should have(5).items
    id_table["a"].children.should have(1).item
    id_table["a"].children[0].message.message_id == "b"
    id_table["a"].children[0].children[0].message.message_id == "c"
    id_table["a"].children[0].children[0].children[0].message.message_id == "d"
    id_table["a"].children[0].children[0].children[0].children[0].message.message_id == "e"
    id_table["d"].children.should have(1).item
    id_table["d"].children[0].message.message_id == "e"
  end
  
  # it "should create id_table for each message" do
  #     messages = parse_messages 'inbox_fixture_1.yml'
  #     id_table = @thread.create_id_table(messages)
  #     
  #     id_table["a"].children.should have(2).items
  #     id_table["a"].children[0].message.message_id.should == "b"
  #     id_table["a"].children[1].message.message_id.should == "f"
  #     id_table["b"].children.should have(1).item
  #     id_table["b"].children[0].message.message_id.should == "d"
  #     id_table["c"].children.should be_empty
  #     id_table["d"].children.should have(1).item
  #     id_table["d"].children[0].message.message_id.should == "e"
  #     id_table["e"].children.should be_empty
  #     
  #     #@debug.print_hash(id_table)  
  #   end
  #   
  #   it "should create tree model of all messages" do
  #     messages = parse_messages 'inbox_fixture_1.yml'
  #     id_table = @thread.create_id_table(messages)
  #     root = @thread.create_root_hierachy_2(id_table)
  #    
  #     root.children.should have(2).items
  #     root.children[0].message.message_id.should == "a" 
  #     root.children[1].message.message_id.should == "c"
  #     
  #     #@debug.print_tree(root)
  #   end
  #   
  #   it "should create tree model of all messages including multiple references with empty containers" do
  #     messages = parse_messages 'inbox_fixture_2.yml'
  #     id_table = @thread.create_id_table(messages)
  #     #@debug.print_hash(id_table) 
  #     
  #     root = @thread.create_root_hierachy_2(id_table)
  #     
  #     root.children.should have(3).items
  #     root.children[0].message.message_id.should == "a" 
  #     root.children[1].message.message_id.should == "c"
  #     root.children[2].message.message_id.should == "g"
  #     
  #     #@debug.print_tree(root)
  #   end
  
  it "should prune containers with empty message and no children" do
  
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject", "a", [])
    root.add_child(container_a)
    container_b = Container.new()
    container_b.message = Message.new("subject", "b", "a")
    container_a.add_child(container_b)
    # dummy container
    container_z = Container.new()
    container_b.add_child(container_z)
    
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    root.children.should have(1).item
    root.children[0].should == container_a
    root.children[0].children[0].should == container_b
  end
  
  it "should prune containers with empty message and 1 non-empty child" do 
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject", "a", [])
    root.add_child(container_a)
    container_b = Container.new()
    container_b.message = Message.new("subject", "b", "a")
    container_a.add_child(container_b)
    container_c = Container.new()
    container_c.message = Message.new("subject", "c", ["a", "z"])
    # dummy container
    container_z = Container.new()
    container_b.add_child(container_z)
    container_z.add_child(container_c)
    
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    root.children.should have(1).items
    root.children[0].should == container_a
    root.children[0].children[0] == container_b
    root.children[0].children[0].children[0] == container_c
  end
  
  it "should promote child of containers with empty message and 1 child directly to root level" do 
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject", "a", [])
    root.add_child(container_a)
    container_b = Container.new()
    container_b.message = Message.new("subject", "b", ["z"])
    # dummy container
    container_z = Container.new()
    root.add_child(container_z)
    container_z.add_child(container_b)
    
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].should == container_b
  end
  
  it "should do *not* promote children of containers with empty message and 2 children directly to root level" do 
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject", "a", [])
    root.add_child(container_a)
    # dummy container
    container_z = Container.new()
    root.add_child(container_z)
    # dummy container children
    container_b = Container.new()
    container_b.message = Message.new("subject", "b", ["a", "z"])
    container_z.add_child(container_b)
    container_c = Container.new()
    container_c.message = Message.new("subject", "c", ["a", "z"])
    container_z.add_child(container_c)
    
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].is_dummy.should be_true
    root.children[1].children.should have(2).items
    root.children[1].children[0].should == container_b
    root.children[1].children[1].should == container_c
  end
  
  it "should promote children of containers with empty message and 2 children directly to next level" do 
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject", "a", [])
    root.add_child(container_a)
    # dummy container
    container_z = Container.new()
    root.add_child(container_z)
    # 2nd dummy container
    container_y = Container.new()
    container_z.add_child(container_y)
    # dummy container children
    container_b = Container.new()
    container_b.message = Message.new("subject", "b", ["a", "z"])
    container_y.add_child(container_b)
    container_c = Container.new()
    container_c.message = Message.new("subject", "c", ["a", "z"])
    container_y.add_child(container_c)
    container_d = Container.new()
    container_d.message = Message.new("subject", "d", ["a", "z"])
    container_y.add_child(container_d)
    
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].is_dummy.should be_true
    root.children[1].children.should have(3).items
    root.children[1].children[0].should == container_d
    root.children[1].children[1].should == container_c
    root.children[1].children[2].should == container_b
  end
  
  it "should promote children of several containers with empty message and 2 children directly to next level" do 
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject", "a", [])
    root.add_child(container_a)
    # dummy container
    container_z = Container.new()
    root.add_child(container_z)
    # 2nd dummy container
    container_y = Container.new()
    container_z.add_child(container_y)
    # 3nd dummy container
    container_x = Container.new()
    container_y.add_child(container_x)
    # dummy container children
    container_b = Container.new()
    container_b.message = Message.new("subject", "b", ["a", "z"])
    container_x.add_child(container_b)
    container_c = Container.new()
    container_c.message = Message.new("subject", "c", ["a", "z"])
    container_x.add_child(container_c)
    
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].is_dummy.should be_true
    root.children[1].children.should have(2).items
    root.children[1].children[0].should == container_b
    root.children[1].children[1].should == container_c
  end
  
  it "should promote children of several containers with empty message and 2 children directly to next level" do 
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject", "a", [])
    root.add_child(container_a)
    # dummy container
    container_z = Container.new()
    root.add_child(container_z)
    # 2nd dummy container
    container_y = Container.new()
    container_z.add_child(container_y)
    # 3nd dummy container
    container_x = Container.new()
    container_y.add_child(container_x)
    # dummy container children
    container_b = Container.new()
    container_b.message = Message.new("subject", "b", ["a", "z"])
    container_x.add_child(container_b)
    container_c = Container.new()
    container_c.message = Message.new("subject", "c", ["a", "z"])
    container_x.add_child(container_c)
    container_d = Container.new()
    container_d.message = Message.new("subject", "d", ["a", "z"])
    container_z.add_child(container_d)
    
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].is_dummy.should be_true
    root.children[1].children.should have(3).items
    root.children[1].children[0].should == container_d
    root.children[1].children[1].should == container_b
    root.children[1].children[2].should == container_c
  end
  
  it "should promote children of several containers with empty message and multiple children" do 
    root = Container.new
    container_dummy_1 = Container.new
    root.add_child(container_dummy_1)
      container_dummy_2 = Container.new
      container_dummy_1.add_child(container_dummy_2)
        container_dummy_3_a = Container.new
        container_dummy_2.add_child(container_dummy_3_a)
          container_dummy_4 = Container.new
          container_dummy_3_a.add_child(container_dummy_4)
            container_4_a = Container.new
            container_4_a.message = Message.new("", "a", [])
            container_dummy_4.add_child(container_4_a)
        container_dummy_3_b = Container.new
        container_dummy_1.add_child(container_dummy_3_b)
        
              
              
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    # root.children.should have(2).items
    #     root.children[0].should == container_a
    #     root.children[1].is_dummy.should be_true
    #     root.children[1].children.should have(3).items
    #     root.children[1].children[0].should == container_d
    #     root.children[1].children[1].should == container_b
    #     root.children[1].children[2].should == container_c
  end
  
  it "should promote children of several containers with empty message and multiple children" do 
    root = Container.new
    container_dummy_1 = Container.new
    root.add_child(container_dummy_1)
      container_dummy_2 = Container.new
      container_dummy_1.add_child(container_dummy_2)
        container_dummy_3_a = Container.new
        container_dummy_2.add_child(container_dummy_3_a)
          container_dummy_4 = Container.new
          container_dummy_3_a.add_child(container_dummy_4)
            container_4_a = Container.new
            container_4_a.message = Message.new("", "a", [])
            container_dummy_4.add_child(container_4_a)
            container_4_b = Container.new
            container_4_b.message = Message.new("", "b", [])
            container_dummy_4.add_child(container_4_b)
        container_dummy_3_b = Container.new
        container_dummy_1.add_child(container_dummy_3_b)
        
              
              
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    # root.children.should have(2).items
    #     root.children[0].should == container_a
    #     root.children[1].is_dummy.should be_true
    #     root.children[1].children.should have(3).items
    #     root.children[1].children[0].should == container_d
    #     root.children[1].children[1].should == container_b
    #     root.children[1].children[2].should == container_c
  end
  
  
  it "should promote children of several containers with empty message and multiple children" do 
    root = Container.new
    container_dummy_1 = Container.new
    root.add_child(container_dummy_1)
      container_dummy_2 = Container.new
      container_dummy_1.add_child(container_dummy_2)
        container_dummy_3_a = Container.new
        container_dummy_2.add_child(container_dummy_3_a)
          container_dummy_4 = Container.new
          container_dummy_3_a.add_child(container_dummy_4)
            container_4_a = Container.new
            container_4_a.message = Message.new("", "a", [])
            container_dummy_4.add_child(container_4_a)
              container_5_a = Container.new
              container_5_a.message = Message.new("", "b", [])
              container_4_a.add_child(container_5_a)
            container_4_b = Container.new
            container_4_b.message = Message.new("", "c", [])
            container_dummy_4.add_child(container_4_b)
              container_5_b = Container.new
              container_5_b.message = Message.new("", "d", [])
              container_4_b.add_child(container_5_b)
        container_dummy_3_b = Container.new
        container_dummy_1.add_child(container_dummy_3_b)

              
              
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    # root.children.should have(2).items
    #     root.children[0].should == container_a
    #     root.children[1].is_dummy.should be_true
    #     root.children[1].children.should have(3).items
    #     root.children[1].children[0].should == container_d
    #     root.children[1].children[1].should == container_b
    #     root.children[1].children[2].should == container_c
  end
  
  it "should promote children of several containers with empty message and multiple children" do 
    root = Container.new
    container_dummy_1 = Container.new
    root.add_child(container_dummy_1)
      container_dummy_2 = Container.new
      container_dummy_1.add_child(container_dummy_2)
        container_dummy_3_a = Container.new
        container_dummy_2.add_child(container_dummy_3_a)
          container_dummy_4 = Container.new
          container_dummy_3_a.add_child(container_dummy_4)
            container_4_a = Container.new
            container_4_a.message = Message.new("", "a", [])
            container_dummy_4.add_child(container_4_a)
              container_5_a = Container.new
              container_5_a.message = Message.new("", "b", [])
              container_4_a.add_child(container_5_a)
            container_4_b = Container.new
            container_4_b.message = Message.new("", "c", [])
            container_dummy_4.add_child(container_4_b)
              container_5_b = Container.new
              container_5_b.message = Message.new("", "d", [])
              container_4_b.add_child(container_5_b)
        container_dummy_3_b = Container.new
        container_dummy_1.add_child(container_dummy_3_b)
          container_dummy_4_b = Container.new
                   container_dummy_3_b.add_child(container_dummy_4_b)
                     container_dummy_5_b = Container.new
                     container_dummy_4_b.add_child(container_dummy_5_b)
                       container_dummy_6_b = Container.new
                       container_dummy_5_b.add_child(container_dummy_6_b)
                         container_dummy_7_b = Container.new
                         container_dummy_6_b.add_child(container_dummy_7_b)
                           container_8_b = Container.new
                           container_8_b.message = Message.new("", "e", [])
                           container_dummy_7_b.add_child(container_8_b)
                     container_dummy_5_c = Container.new
                     container_dummy_4_b.add_child(container_dummy_5_c)
                       container_6_b = Container.new
                       container_6_b.message = Message.new("", "f", [])
                       container_dummy_5_c.add_child(container_6_b)
              
              
    #@debug.print_tree(root)
    @thread.prune_empty_containers(root)
    #@debug.print_tree(root)
    
    # root.children.should have(2).items
    #     root.children[0].should == container_a
    #     root.children[1].is_dummy.should be_true
    #     root.children[1].children.should have(3).items
    #     root.children[1].children[0].should == container_d
    #     root.children[1].children[1].should == container_b
    #     root.children[1].children[2].should == container_c
  end
  
  it "should promote children of several containers with empty message and multiple children" do 
     root = Container.new
     container_dummy_1 = Container.new
     root.add_child(container_dummy_1)
       container_dummy_2 = Container.new
       container_dummy_1.add_child(container_dummy_2)
         container_dummy_3_a = Container.new
         container_dummy_2.add_child(container_dummy_3_a)
           container_dummy_4 = Container.new
           container_dummy_3_a.add_child(container_dummy_4)
             container_4_a = Container.new
             container_4_a.message = Message.new("", "a", [])
             container_dummy_4.add_child(container_4_a)
               container_5_a = Container.new
               container_5_a.message = Message.new("", "b", [])
               container_4_a.add_child(container_5_a)
             container_4_b = Container.new
             container_4_b.message = Message.new("", "c", [])
             container_dummy_4.add_child(container_4_b)
               container_5_b = Container.new
               container_5_b.message = Message.new("", "d", [])
               container_4_b.add_child(container_5_b)


     @debug.print_tree(root)
     @thread.prune_empty_containers(root)
     @debug.print_tree(root)

     # root.children.should have(2).items
     #     root.children[0].should == container_a
     #     root.children[1].is_dummy.should be_true
     #     root.children[1].children.should have(3).items
     #     root.children[1].children[0].should == container_d
     #     root.children[1].children[1].should == container_b
     #     root.children[1].children[2].should == container_c
   end

  it "should group all messages in the root set by subject" do
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject_a", "a", [])
    root.add_child(container_a)
    container_b = Container.new()
    container_b.message = Message.new("Re: subject_z", "b", [])
    container_c = Container.new()
    container_c.message = Message.new("Re: subject_z", "c", [])
    container_d = Container.new()
    container_d.message = Message.new("subject_z", "d", [])
    root.add_child(container_b)
    root.add_child(container_c)
    root.add_child(container_d)

    # @debug.print_tree(root)    
    @thread.prune_empty_containers(root)
    #    @debug.print_tree(root)
    
    subject_hash = @thread.group_root_set_by_subject(root)
    
    #@debug.print_subject_hash(subject_hash)
    # @debug.print_tree(root)
    subject_hash.key?("subject_a").should == true
    subject_hash.key?("subject_z").should == true
  end
 

  
  it "should create tree" do    
    messages = Hash.new
    messages["a"] = Message.new("subject", "a", "")
    messages["b"] = Message.new("subject", "b", "a")
    messages["c"] = Message.new("subject", "c", ["a", "b"])
    messages["d"] = Message.new("subject", "d", ["a", "b", "c"])
    messages["e"] = Message.new("subject", "e", "d")
    messages["f"] = Message.new("Hello", "f", "")
    messages["g"] = Message.new("Re:Hello", "g", "")
    messages["h"] = Message.new("Re:Hello", "h", "")            
    messages["i"] = Message.new("Fwd:Hello", "i", "")
    messages["j"] = Message.new("Re:Re: Hello", "j", "")            
    
    #@debug.print_tree(messages)
    
    root = @thread.thread(messages)
    #subject_hash = @thread.group_root_set_by_subject(root)
  
    #@debug.print_subject_hash subject_hash
    #@debug.print_tree(root)
    
  end
  
  it "should create tree with nested dummies" do    
    messages = Hash.new
    messages["a"] = Message.new("subject", "a", "")
    messages["b"] = Message.new("subject", "b", "a")
    messages["c"] = Message.new("subject", "c", ["a", "b"])
    messages["d"] = Message.new("subject", "d", ["a", "b", "c"])
    messages["e"] = Message.new("subject", "e", "d")
    messages["f"] = Message.new("Hello", "f", ["x", "y", "z"])
    messages["g"] = Message.new("Re:Hello", "g", ["f", "x", "y", "z"])
    messages["h"] = Message.new("Re:Hello", "h", ["x", "y", "z"])            
    messages["i"] = Message.new("Fwd:Hello", "i", ["x", "y", "z"])
            
    
    #@debug.print_tree(messages)
    
    root = @thread.thread(messages)
    #subject_hash = @thread.group_root_set_by_subject(root)
  
    #@debug.print_subject_hash subject_hash
    #puts "------------------"
    #@debug.print_tree(root)
    
  end
  
end
