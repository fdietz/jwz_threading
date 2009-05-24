require File.join(File.dirname(__FILE__), 'test_helper')


class MessageParserTest < Test::Unit::TestCase

  test "should not normalize subject cause no prefix to remove exists" do
    subject = "Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal subject, result
  end

  test "should normalize subject by removing Re: prefix" do
    subject = "Re:Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing RE: prefix" do
    subject = "RE:Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing Re: Re:[2] prefix" do
    subject = "Re: Re[2]:Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing RE:[2] prefix" do
    subject = "Re[2]:Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing Re:+whtestespace prefix" do
    subject = "Re: Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing Re:Re: prefix" do
    subject = "Re:Re:Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing Re: Re: prefix" do
    subject = "Re: Re: Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing Fwd: prefix" do
    subject = "Fwd:Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing all Fwd: prefix" do
    subject = "Fwd:Fwd:Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing Fwd: prefix and ignoring whitespaces" do
    subject = "Fwd: Fwd: Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should normalize subject by removing Fwd:+whitespace prefix" do
    subject = "Fwd: Subject"
    result = MailHelper::MessageParser.normalize_subject(subject)
    assert_equal "Subject", result
  end

  test "should check if subject is starting wtesth re or fwd" do
    subject = "Fwd: Subject"
    assert MailHelper::MessageParser.is_reply_or_forward(subject)
  end

  test "should check if subject is starting with re or fwd" do
    subject = "Subject"
    assert !MailHelper::MessageParser.is_reply_or_forward(subject)
  end

  test "should check if subject is starting with re or RE" do
    subject = "RE: Re: Subject"
    assert MailHelper::MessageParser.is_reply_or_forward(subject)

  end

  test "should find 1 message-id" do
    str = "<e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com>"
    message_id = "e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com"
    result = MailHelper::MessageParser.normalize_message_id(str)
    assert_equal message_id, result
  end

  test "should find 1 message-id ignoring prefix" do
    str = "sadf asdf <e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com>"
    message_id = "e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com"
    result = MailHelper::MessageParser.normalize_message_id(str)
    assert_equal message_id, result
  end

  test "should find 1 message-id ignoring suffix" do
    str = "<e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com> asd sf"
    message_id = "e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com"
    result = MailHelper::MessageParser.normalize_message_id(str)      
    assert_equal message_id, result
  end

  test "should return nil in case no message-ID can be found" do
    str = "a b c"
    message_id = nil
    result = MailHelper::MessageParser.normalize_message_id(str)
    assert_nil result
  end

  test "should find 1 message-id in in_reply_to header" do
    str = "<e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com> asd sf"
    message_id = ["e22ff8510609251339s53fed0dcka38d118e00ed9ef7@mail.gmail.com"]
    result = MailHelper::MessageParser.parse_in_reply_to(str)      
    assert_equal message_id, result
  end


  test "should find 2 message-id in in-reply-to header" do
    str = "<a@mail.gmail.com> <b@mail.gmail.com>"
    message_id = ["a@mail.gmail.com", "b@mail.gmail.com"]
    result = MailHelper::MessageParser.parse_in_reply_to(str)      
    assert_equal message_id, result
  end

  test "should find 2 message-id in references header" do
    str = "<a@mail.gmail.com> <b@mail.gmail.com>"
    message_id = ["a@mail.gmail.com", "b@mail.gmail.com"]
    result = MailHelper::MessageParser.parse_references(str)      
    assert_equal message_id, result
  end

  test "should find 2 message-id in references header ignoring prefix and suffix" do
    str = "sdf <a> sdf <b> sdf"
    message_id = ["a", "b"]
    result = MailHelper::MessageParser.parse_references(str)      
    assert_equal message_id, result
  end

end