#!/user/bin/ruby


class MessageParser
        
  # Subject comparison are case-insensitive      
  def self.is_reply_or_forward(subject)
    pattern = /^(Re|Fwd)/i  
   
    #return pattern =~ subject
    
    if pattern =~ subject 
      return true
    else
      return false
    end   
  end

  # Subject comparison are case-insensitive  
  def self.normalize_subject(subject)
    pattern = /((Re|Fwd)(\[[\d+]\])?:(\s)?)*([\w]*)/i  
    if pattern =~ subject
      return $5
    end
    subject
  end
  

  # return first found message-ID
  def self.normalize_message_id(message_id)
    # match all characters between "<" and ">"
    pattern = /<([^<>]+)>/
    
    if pattern =~ message_id
      return $1
    elsif
      raise ValueError, "Message does not contain a Message-ID: header"
    end
  end

  # return array containing all found message-IDs
  def self.parse_in_reply_to(in_reply_to)
     # match all characters between "<" and ">"
     pattern = /<([^<>]+)>/

      # returns an array for each matches, for each group
      result = in_reply_to.scan(pattern)
      # flatten nested array to a single array
      result.flatten
  end
  
  # return array of matched message-IDs in references header
  def self.parse_references(references)    
    pattern = /<([^<>]+)>/
    # returns an array for each matches, for each group
    result = references.scan(pattern)
    # flatten nested array to a single array
    result.flatten
  end
  
  
end