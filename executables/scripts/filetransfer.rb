# encoding: utf-8

Script :DCC do
  def message user, channel, line
    if line.starts_with? '.dcc'
      @client.send_file '/home/mk/Desktop/Scr000017.jpg', 'mk_'
    end
  end

  def dcc_resume_file user, conversation, args
    
  end
end
