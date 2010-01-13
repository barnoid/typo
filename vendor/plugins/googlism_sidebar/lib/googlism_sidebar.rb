class GooglismSidebar < Sidebar

  description "A random googlism"

  #setting :title, 'Links'
  #setting :body,  DEFAULT_TEXT, :input_type => :text_area
  

  def getquote
    quote = ""
    File.open(File.dirname(__FILE__) + '/googlism-cache') do |file|
      lines = file.readlines
      line = lines[rand(lines.length)]
      quote = line.split(">")[0]
    end
    return quote
  end

end
