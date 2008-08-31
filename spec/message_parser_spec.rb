require 'lib/message_parser.rb'

describe "Message Parser" do

  before(:each) do
  end
  
  it "should not normalize subject cause no prefix to remove exists" do
    subject = "Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == subject
  end
      
  it "should normalize subject by removing Re: prefix" do
    subject = "Re:Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing RE: prefix" do
    subject = "RE:Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Re: Re:[2] prefix" do
     subject = "Re: Re[2]:Subject"
     result = MessageParser.normalize_subject(subject)
     result.should == "Subject"
  end

  it "should normalize subject by removing RE:[2] prefix" do
     subject = "Re[2]:Subject"
     result = MessageParser.normalize_subject(subject)
     result.should == "Subject"
   end
 
  it "should normalize subject by removing Re:+whitespace prefix" do
    subject = "Re: Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Re:Re: prefix" do
    subject = "Re:Re:Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Re: Re: prefix" do
    subject = "Re: Re: Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Fwd: prefix" do
    subject = "Fwd:Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Fwd: prefix" do
    subject = "Fwd:Fwd:Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Fwd: prefix" do
    subject = "Fwd: Fwd: Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Fwd:+whitespace prefix" do
    subject = "Fwd: Subject"
    result = MessageParser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should check if subject is starting with re or fwd" do
    subject = "Fwd: Subject"
    result = MessageParser.is_reply_or_forward(subject)
    result.should == true
  end
  it "should check if subject is starting with re or fwd" do
    subject = "Subject"
    result = MessageParser.is_reply_or_forward(subject)
    result.should == false
  end
  
  it "should check if subject is starting with re or fwd" do
     subject = "RE: Re: Subject"
     result = MessageParser.is_reply_or_forward(subject)
     result.should == true
  end
   
  it "should find 1 message-id" do
      str = "<e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com>"
      message_id = "e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com"
      result = MessageParser.normalize_message_id(str)
      result.should == message_id
  end
  
  it "should find 1 message-id" do
      str = "sadf asdf <e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com>"
      message_id = "e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com"
      result = MessageParser.normalize_message_id(str)
      result.should == message_id
  end
  
  it "should find 1 message-id" do
      str = "<e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com> asd sf"
      message_id = "e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com"
      result = MessageParser.normalize_message_id(str)      
      result.should == message_id
  end
     
  it "should find 1 message-id in in_reply_to header" do
      str = "<e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com> asd sf"
      message_id = ["e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com"]
      result = MessageParser.parse_in_reply_to(str)      
      result.should == message_id
  end
  
  
  it "should find 2 message-id in in-reply-to header" do
      str = "<a@mail.gmail.com> <b@mail.gmail.com>"
      message_id = ["a@mail.gmail.com", "b@mail.gmail.com"]
      result = MessageParser.parse_in_reply_to(str)      
      result.should == message_id
  end
  
  it "should find 2 message-id in references header" do
      str = "<a@mail.gmail.com> <b@mail.gmail.com>"
      message_id = ["a@mail.gmail.com", "b@mail.gmail.com"]
      result = MessageParser.parse_references(str)      
      result.should == message_id
  end
  
  it "should find 2 message-id in references header" do
      str = "sdf <a> sdf <b> sdf"
      message_id = ["a", "b"]
      result = MessageParser.parse_references(str)      
      result.should == message_id
  end
  
end 