#!/user/bin/ruby

# TODO: use class-level methods instead
class MessageParser
        
  # Subject comparison are case-insensitive      
  def is_reply_or_forward(subject)
    pattern = /^(Re|Fwd)/i  
   
    #return pattern =~ subject
    
    if pattern =~ subject 
      return true
    else
      return false
    end   
  end

  # Subject comparison are case-insensitive  
  def normalize_subject(subject)
    pattern = /((Re|Fwd)(\[[\d+]\])?:(\s)?)*([\w]*)/i  
    if pattern =~ subject
      return $5
    end
    subject
  end
  
end