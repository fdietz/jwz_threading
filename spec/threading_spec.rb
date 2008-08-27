#require 'rubygems'
#require 'spec'

require 'lib/threading.rb'
require 'lib/threading_debug.rb'
require 'lib/message_parser.rb'


describe "JWZ threading algorithm" do
  
  def path_helper(file)
    File.dirname(__FILE__) + file
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
    
    id_table.size.should == 2
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
    id_table.size.should == 2
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
    id_table.size.should == 5
    id_table["a"].children.size.should == 3
    id_table["a"].children[0].message.message_id == "b"
    id_table["a"].children[2].message.message_id == "d"
    id_table["a"].children[2].children[0].message.message_id == "e"
    id_table["d"].children.size == 1
    id_table["d"].children[0].message.message_id == "e"
  end
  
  it "should create id_table for each message" do
    messages = parse_messages 'inbox_fixture_1.yml'
    id_table = @thread.create_id_table(messages)
    
    id_table["a"].children.size.should == 2
    id_table["a"].children[0].message.message_id.should == "b"
    id_table["a"].children[1].message.message_id.should == "f"
    id_table["b"].children.size.should == 1
    id_table["b"].children[0].message.message_id.should == "d"
    id_table["c"].children.size.should == 0
    id_table["d"].children.size.should == 1
    id_table["d"].children[0].message.message_id.should == "e"
    id_table["e"].children.size.should == 0
    
    #@debug.print_hash(id_table)  
  end
  
  it "should create tree model of all messages" do
    messages = parse_messages 'inbox_fixture_1.yml'
    id_table = @thread.create_id_table(messages)
    root = @thread.create_root_hierachy_2(id_table)
   
    root.children.size.should == 2
    root.children[0].message.message_id.should == "a" 
    root.children[1].message.message_id.should == "c"
    
    #@debug.print_tree(root)
  end
  
  it "should create tree model of all messages including multiple references with empty containers" do
    messages = parse_messages 'inbox_fixture_2.yml'
    id_table = @thread.create_id_table(messages)
    #@debug.print_hash(id_table) 
    
    root = @thread.create_root_hierachy_2(id_table)
    
    root.children.size.should == 3
    root.children[0].message.message_id.should == "a" 
    root.children[1].message.message_id.should == "c"
    root.children[2].message.message_id.should == "g"
    
    #@debug.print_tree(root)
  end
  
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
    #@thread.prune_empty_containers(root)
    #@debug.print_tree(root)
  end
  
  it "should prune containers with empty message and 1 child" do 
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
    
    # @debug.print_tree(root)
    #     @thread.prune_empty_containers(root)
    #     @debug.print_tree(root)
  end
  
  it "should promote child of containers with empty message and 1 child directly on root level" do 
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
    
    # @debug.print_tree(root)
    # @thread.prune_empty_containers(root)
    # @debug.print_tree(root)
  end
  
  it "should do *not* promote children of containers with empty message and 2 children directly on root level" do 
    root = Container.new()
    container_a = Container.new()
    container_a.message = Message.new("subject", "a", [])
    root.add_child(container_a)
    container_b = Container.new()
    container_b.message = Message.new("subject", "b", ["a", "z"])
    container_c = Container.new()
    container_c.message = Message.new("subject", "c", ["a", "z"])
    # dummy container
    container_z = Container.new()
    root.add_child(container_z)
    container_z.add_child(container_b)
    container_z.add_child(container_c)
    
    # @debug.print_tree(root)
    # @thread.prune_empty_containers(root)
    # @debug.print_tree(root)
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
    
    @debug.print_subject_hash(subject_hash)
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
    @debug.print_tree(root)
    
  end
  
end
