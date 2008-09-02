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
        m = MailHelper::Message.new(value["subject"], key, ref)
        messages[key] = m
      end

      messages
    end
  end
  
  def parse_messages(file)
    parser = Parser.new
    messages = parser.parse_inbox path_helper("/#{file}")
  end
  
  ########### helper methods: begin
  
  def message(subject, message_id, references)
    MailHelper::Message.new(subject, message_id, references)
  end
  
  def empty_container()
    MailHelper::Container.new
  end
  
  def container(subject, message_id, references)
    MailHelper::Container.new message(subject, message_id, references)
  end
  
  ########### helper methods: end
  
  before(:each) do
    @thread = MailHelper::Threading.new
    # change log level
    log = Logging::Logger['Threading']
    log.level = :info
      
    @debug = MailHelper::Debug.new
    @message_parser = MailHelper::MessageParser.new
  end
  
  it "should create valid message by using references field" do
    message = MailHelper::MessageFactory.create("subject", "message_id", ["a"], ["a", "c"])
    message.references.should == ["a", "c"]
  end
  
  it "should create valid message by using in-reply-to field" do
    message = MailHelper::MessageFactory.create("subject", "message_id", ["a"], nil)
    message.references.should == ["a"]
  end
  
  it "should create valid message by using in-reply-to field with multiple message-IDs" +
  " but taking only the first message-ID into account" do
    message = MailHelper::MessageFactory.create("subject", "message_id", ["a", "c"], nil)
    message.references.should == ["a"]
  end
  
  #
  # a:subject(1) 
  #   +- 2786200: b::subject(1) 
  #     +- 2785770: c::subject(1) 
  #       +- 2784990: d::subject(1) 
  #         +- 2781700: e::subject
  # b:subject(1) 
  #   +- 2785770: c::subject(1) 
  #     +- 2784990: d::subject(1) 
  #       +- 2781700: e::subject
  # c:subject(1) 
  #   +- 2784990: d::subject(1) 
  #     +- 2781700: e::subject
  # d:subject(1) 
  #   +- 2781700: e::subject
  # e:subject
  #
  it "should create id_table for each message" do
    messages = Hash.new
    messages["a"] = message("subject", "a", "")
    messages["b"] = message("subject", "b", "a")
    messages["c"] = message("subject", "c", ["a", "b"])
    messages["d"] = message("subject", "d", ["a", "b", "c"])
    messages["e"] = message("subject", "e", "d")
 
    id_table = @thread.create_id_table(messages)
        
    id_table.should have(5).items
    id_table["a"].children.should have(1).item
    id_table["a"].children[0].message.message_id == "b"
    
    id_table["b"].children.should have(1).items
    id_table["b"].children[0].message.message_id == "c"

    id_table["c"].children.should have(1).items
    id_table["c"].children[0].message.message_id == "d"
    
    id_table["d"].children.should have(1).item
    id_table["d"].children[0].message.message_id == "e"
    
    id_table["e"].children.should be_empty
  end
  
  #
  # a:subject(1) 
  #   +- 2760450: b::subject(1) 
  #     +- 2759470: (dummy)
  #       +- 2760060: d::subject(1) 
  #         +- 2759140: e::subject
  # b:subject(1) 
  #   +- 2759470: (dummy)
  #     +- 2760060: d::subject(1) 
  #      +- 2759140: e::subject
  # c(1) 
  #   +- 2760060: d::subject(1) 
  #     +- 2759140: e::subject
  # d:subject(1) 
  #   +- 2759140: e::subject
  # e:subject
  #
  it "should create id_table for each message and dummy containers in case of"+
  " reference to non-existent message" do
    messages = Hash.new
    messages["a"] = message("subject", "a", "")
    messages["b"] = message("subject", "b", "a")
    # message "c" is the dummy
    messages["d"] = message("subject", "d", ["a", "b", "c"])
    messages["e"] = message("subject", "e", "d")
 
    id_table = @thread.create_id_table(messages)
      
    id_table.should have(5).items
    id_table["a"].children.should have(1).item
    id_table["a"].children[0].message.message_id == "b"
    
    # dummy "c" checked
    id_table["b"].children.should have(1).items
    id_table["b"].children[0].message.should be_nil

    id_table["c"].children.should have(1).item
    id_table["c"].children[0].message.message_id == "d"
    
    id_table["d"].children.should have(1).item
    id_table["d"].children[0].message.message_id == "e"
    
    id_table["e"].children.should be_empty  
  end
  
  #
  # a:subject(1) 
  #   +- 2730500: b::subject(1) 
  #     +- 2729390: (dummy)
  # b:subject(1) 
  #   +- 2729390: (dummy)
  # y(1) 
  #   +- 2730090: d::subject(1) 
  #     +- 2729010: e::subject
  # c
  # z(1) 
  #   +- 2728640: (dummy)
  #     +- 2730090: d::subject(1) 
  #       +- 2729010: e::subject
  # d:subject(1) 
  #   +- 2729010: e::subject
  # e:subject
  #  
  it "should create id_table for each message and nested dummy containers in case of"+
  " references to non-existent messages" do
    messages = Hash.new
    messages["a"] = message("subject", "a", "")
    messages["b"] = message("subject", "b", "a")
    # message "c" is the dummy
    messages["d"] = message("subject", "d", ["a", "b", "c"])
    messages["e"] = message("subject", "e", ["z", "y", "d"])
 
    id_table = @thread.create_id_table(messages)
    #@debug.print_hash(id_table)
 
    id_table.should have(7).items
    id_table["a"].children.should have(1).item
    id_table["a"].children[0].message.message_id == "b"
    
    # dummy "c" checked
    id_table["b"].children.should have(1).items
    id_table["b"].children[0].should be_dummy

    id_table["c"].should be_dummy
    id_table["c"].children.should be_empty
    
    id_table["z"].children.should have(1).items
    id_table["z"].children[0].should be_dummy
    
    id_table["y"].children.should have(1).items
    id_table["y"].children[0].message.message_id == "d"
    
    id_table["d"].children.should have(1).item
    id_table["d"].children[0].message.message_id == "e"
    
    id_table["e"].children.should be_empty  
  end
  
  #
  # before: 
  # a
  # +- b
  #   +- dummy 
  #  
  # after:
  # a
  # +- b
  # 
  it "should prune containers with empty message and no children" do  
    root = empty_container
    container_a = container("subject", "a", [])
    root.add_child container_a
    container_b = container("subject", "b", "a")
    container_a.add_child container_b
    # dummy container
    container_z = empty_container
    container_b.add_child(container_z)
    
    @thread.prune_empty_containers(root)
    
    root.children.should have(1).item
    root.children[0].should == container_a
    container_a.children.should have(1).item
    container_a.children[0].should == container_b
    container_b.children.should be_empty
  end
  
  # 
  # before: 
  # a
  # +- b
  #    +- z (dummy)
  #       +- c
  #
  # after:
  # a
  # +- b
  #    +- c
  #  
  it "should prune containers with empty message and 1 non-empty child" do 
    root = empty_container
    container_a = container("subject", "a", [])
    root.add_child container_a
    container_b = container("subject", "b", "a")
    container_a.add_child container_b
    container_c = container("subject", "c", ["a", "z"])
    # dummy container
    container_z = empty_container
    container_b.add_child container_z
    container_z.add_child container_c
    
    @thread.prune_empty_containers(root)
    
    root.children.should have(1).items
    root.children[0].should == container_a
    container_a.children[0] == container_b
    container_b.children[0].children[0] == container_c
  end
  
  #
  # before:
  # a
  # z (dummy)
  # +- c
  #
  # after:
  # a
  # b
  #
  #
  it "should promote child of containers with empty message and 1 child directly to root level" do 
    root = empty_container
    
    container_a = container("subject", "a", [])
    root.add_child(container_a)
    container_b = container("subject", "b", ["z"])
    # dummy container
    container_z = empty_container
    root.add_child(container_z)
    container_z.add_child(container_b)
    
    @thread.prune_empty_containers(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].should == container_b
  end
  
  #
  # before:
  # a
  # z (dummy)
  # +- b
  # +- c
  #
  # after:
  # a
  # z (dummy)
  # +- b
  # +- c
  # 
  it "should do *not* promote children of containers with empty message and 2 children directly to root level" do 
    root = empty_container
    container_a = container("subject", "a", [])
    root.add_child container_a
    # dummy container
    container_z = empty_container
    root.add_child container_z
    # dummy container children
    container_b = container("subject", "b", ["a", "z"])
    container_z.add_child container_b
    container_c = container("subject", "c", ["a", "z"])
    container_z.add_child container_c
    
    @thread.prune_empty_containers(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].should be_dummy
    container_z.children.should have(2).items
    container_z.children[0].should == container_b
    container_z.children[1].should == container_c
  end
  
  
  #
  # before:
  # a
  # z (dummy)
  # +- y (dummy)
  #    +- b
  #    +- c
  #    +- d
  #
  # after:
  # a
  # z (dummy)
  # +- b 
  # +- c
  # +- d
  # 
  it "should promote children of containers with empty message and 2 children directly to next level" do 
    root = empty_container
    container_a = container("subject", "a", [])
    root.add_child container_a
    # dummy container
    container_z = empty_container
    root.add_child container_z
    # 2nd dummy container
    container_y = empty_container
    container_z.add_child container_y
    # dummy container children
    container_b = container("subject", "b", ["a", "z"])
    container_y.add_child container_b
    container_c = container("subject", "c", ["a", "z"])
    container_y.add_child container_c
    container_d = container("subject", "d", ["a", "z"])
    container_y.add_child container_d
    
    @thread.prune_empty_containers(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].should be_dummy
    root.children[1].children.should have(3).items
    root.children[1].children[0].should == container_d
    root.children[1].children[1].should == container_c
    root.children[1].children[2].should == container_b
  end
  
  
  #
  # before:
  # a
  # z (dummy)
  # +- y (dummy)
  #    +- x (dummy)
  #       +- b
  #       +- c
  # +- d
  #
  # after:
  # a
  # z (dummy)
  # +- b
  # +- c
  # +- d
  # 
  it "should promote children of several containers with empty message and 2 children directly to next level" do 
    root = empty_container
    container_a = container("subject", "a", [])
    root.add_child container_a
    # dummy container
    container_z = empty_container
    root.add_child container_z
    # 2nd dummy container
    container_y = empty_container
    container_z.add_child container_y
    # 3nd dummy container
    container_x = empty_container
    container_y.add_child container_x
    # dummy container children
    container_b = container("subject", "b", ["a", "z"])
    container_x.add_child container_b
    container_c = container("subject", "c", ["a", "z"])
    container_x.add_child container_c
    container_d = container("subject", "d", ["a", "z"])
    container_z.add_child container_d
    
    @thread.prune_empty_containers(root)
    
    root.children.should have(2).items
    root.children[0].should == container_a
    root.children[1].should be_dummy
    container_z.children.should have(3).items
    container_z.children[0].should == container_d
    container_z.children[1].should == container_b
    container_z.children[2].should == container_c
  end
  
  #
  # before:
  # z (dummy)
  # +- y (dummy)
  #    +- a
  # +- x (dummy)
  #
  # after:
  # a
  #
  it "should promote children of several containers with empty message and multiple children" do 
    root = empty_container
    container_z = empty_container
    root.add_child(container_z)
    container_y = empty_container
    container_z.add_child container_y
    container_a = container("subject", "a", [])
    container_y.add_child container_a
    container_x = empty_container
    container_z.add_child container_x
      
    @thread.prune_empty_containers(root)
    
    root.children.should have(1).item
    root.children[0].should == container_a
    container_a.children.should be_empty
  end
  
  #
  # before:
  # z (dummy)
  # +- y (dummy)
  #    +- x (dummy)
  #       +- w (dummy)
  #          +- a
  #             +- b
  #          +- c
  #             +- d
  # +- v
  #
  # after:
  # z (dummy)
  # +- a
  #    +- b
  # +- c
  #    +- d
  #  
  it "should promote children of several containers with empty message and multiple children" do 
    
    root = empty_container
    container_z = empty_container
    root.add_child(container_z)
    container_y = empty_container
    container_z.add_child container_y
    container_x = empty_container
    container_y.add_child container_x
    container_w = empty_container
    container_x.add_child container_w
    container_a = container("subject", "a", [])
    container_w.add_child container_a
    container_b = container("subject", "b", [])
    container_a.add_child container_b
    container_c = container("subject","c", [])
    container_w.add_child container_c
    container_d = container("subject", "d", [])
    container_c.add_child container_d
    container_v = empty_container
    container_z.add_child container_v
    
    @thread.prune_empty_containers(root)

    root.children.should have(1).item
    root.children[0].should == container_z
    container_z.children.should have(2).items
    container_z.children[0].should == container_c
    container_z.children[1].should == container_a
    container_a.children[0].should == container_b
    container_c.children[0].should == container_d
  end
  

  #
  # before:
  # z (dummy)
  # +- y (dummy)
  #    +- x (dummy)
  #       +- w (dummy)
  #          +- a
  #             +- b 
  #          +- c   
  #             +- d
  #    +- v
  #       +- u
  #          +- t  
  #             +- s
  #                +- q  
  #                   +- e
  #          +- p
  #             +- f
  #
  # after:
  # z (dummy) 
  # +- a
  #    +- b
  # +- c
  #    +- d
  # +- e
  # +- f
  # 
  it "should promote children of several containers with empty message and multiple children" do 
    root = empty_container
    container_z = empty_container
    root.add_child(container_z)
    container_y = empty_container
    container_z.add_child container_y
    container_x = empty_container
    container_y.add_child container_x
    container_w = empty_container
    container_x.add_child container_w
    container_a = container("subject", "a", [])
    container_w.add_child container_a
    container_b = container("subject", "b", [])
    container_a.add_child container_b
    container_c = container("subject","c", [])
    container_w.add_child container_c
    container_d = container("subject", "d", [])
    container_c.add_child container_d
    container_v = empty_container
    container_z.add_child container_v
    container_u = empty_container
    container_v.add_child container_u
    container_t = empty_container
    container_u.add_child container_t
    container_s = empty_container
    container_t.add_child container_s
    container_q = empty_container
    container_t.add_child container_q
    container_e = container("subject", "e", [])
    container_q.add_child container_e
    container_p = empty_container
    container_u.add_child container_p
    container_f = container("subject", "f", [])
    container_p.add_child container_f
    
    @thread.prune_empty_containers(root)
    
    root.children.should have(1).item
    root.children[0].should == container_z
    container_z.children.should have(4).items
    container_z.children[0].should == container_f
    container_z.children[1].should == container_e
    container_z.children[2].should == container_c
    container_z.children[3].should == container_a
    
    container_a.children[0].should == container_b
    container_c.children[0].should == container_d
  end
  
  it "should group all messages in the root set by subject" do
    root = empty_container
    container_a = empty_container
    container_a.message = message("subject_a", "a", [])
    root.add_child(container_a)
    container_b = empty_container
    container_b.message = message("Re: subject_z", "b", [])
    container_c = empty_container
    container_c.message = message("Re: subject_z", "c", [])
    container_d = empty_container
    container_d.message = message("subject_z", "d", [])
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
    messages["a"] = message("subject", "a", "")
    messages["b"] = message("subject", "b", "a")
    messages["c"] = message("subject", "c", ["a", "b"])
    messages["d"] = message("subject", "d", ["a", "b", "c"])
    messages["e"] = message("subject", "e", "d")
    messages["f"] = message("Hello", "f", "")
    messages["g"] = message("Re:Hello", "g", "")
    messages["h"] = message("Re:Hello", "h", "")            
    messages["i"] = message("Fwd:Hello", "i", "")
    messages["j"] = message("Re:Re: Hello", "j", "")            
    
    #@debug.print_tree(messages)
    
    root = @thread.thread(messages)
    #subject_hash = @thread.group_root_set_by_subject(root)
  
    #@debug.print_subject_hash subject_hash
    #@debug.print_tree(root)
    
  end
  
  it "should create tree with nested dummies" do    
    messages = Hash.new
    messages["a"] = message("subject", "a", "")
    messages["b"] = message("subject", "b", "a")
    messages["c"] = message("subject", "c", ["a", "b"])
    messages["d"] = message("subject", "d", ["a", "b", "c"])
    messages["e"] = message("subject", "e", "d")
    messages["f"] = message("Hello", "f", ["x", "y", "z"])
    messages["g"] = message("Re:Hello", "g", ["f", "x", "y", "z"])
    messages["h"] = message("Re:Hello", "h", ["x", "y", "z"])            
    messages["i"] = message("Fwd:Hello", "i", ["x", "y", "z"])
            
    
    #@debug.print_tree(messages)
    
    root = @thread.thread(messages)
    #subject_hash = @thread.group_root_set_by_subject(root)
  
    #@debug.print_subject_hash subject_hash
    #puts "------------------"
    #@debug.print_tree(root)
    
  end
  
end
