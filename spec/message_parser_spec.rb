require 'lib/message_parser.rb'

describe "Message Parser" do

  before(:each) do
    @message_parser = MessageParser.new
  end
  
  it "should not normalize subject cause no prefix to remove exists" do
    subject = "Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == subject
  end
      
  it "should normalize subject by removing Re: prefix" do
    subject = "Re:Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing RE: prefix" do
    subject = "RE:Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Re: Re:[2] prefix" do
     subject = "Re: Re[2]:Subject"
     result = @message_parser.normalize_subject(subject)
     result.should == "Subject"
  end

  it "should normalize subject by removing RE:[2] prefix" do
     subject = "Re[2]:Subject"
     result = @message_parser.normalize_subject(subject)
     result.should == "Subject"
   end
 
  it "should normalize subject by removing Re:+whitespace prefix" do
    subject = "Re: Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Re:Re: prefix" do
    subject = "Re:Re:Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Re: Re: prefix" do
    subject = "Re: Re: Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Fwd: prefix" do
    subject = "Fwd:Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Fwd: prefix" do
    subject = "Fwd:Fwd:Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Fwd: prefix" do
    subject = "Fwd: Fwd: Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should normalize subject by removing Fwd:+whitespace prefix" do
    subject = "Fwd: Subject"
    result = @message_parser.normalize_subject(subject)
    result.should == "Subject"
  end

  it "should check if subject is starting with re or fwd" do
    subject = "Fwd: Subject"
    result = @message_parser.is_reply_or_forward(subject)
    result.should == true
  end
  it "should check if subject is starting with re or fwd" do
    subject = "Subject"
    result = @message_parser.is_reply_or_forward(subject)
    result.should == false
  end
  
  it "should check if subject is starting with re or fwd" do
     subject = "RE: Re: Subject"
     result = @message_parser.is_reply_or_forward(subject)
     result.should == true
   end
  
end 