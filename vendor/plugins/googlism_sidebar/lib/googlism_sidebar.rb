class GooglismSidebar < Sidebar

  description "A random googlism"

  #setting :title, 'Links'
  #setting :body,  DEFAULT_TEXT, :input_type => :text_area
  

  def getquote
    quote = ""
    File.open('/home/barney/public_html/typo-5.3/vendor/plugins/googlism_sidebar/googlism-cache') do |file|
      lines = file.readlines
      line = lines[rand(lines.length)]
      quote = line.split(">")[0]
    end
    return quote
  end

end
