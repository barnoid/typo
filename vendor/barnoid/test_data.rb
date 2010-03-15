class TestData 

require 'lib/xmlsimple'
require 'digest/md5'

def self.import(file)

puts file

testdata = XmlSimple.xml_in(file, { })['art']

p testdata

testdata.each { |data|
  p data
  newart = Article.find_or_initialize_by_permalink("testdata_#{Digest::MD5.hexdigest(data)}")
  newart.body = data
  newart.excerpt = data.match(/\n([^\n]+)\n/)[1]
  words = data.split(/ |\n/)
  count = 0
  tags = ""
  while count < 6 do
    word = words[rand(words.size)]
    if word.length > 1 then
      tags << "#{word} "
      count = count + 1
    end
  end
  tags << "testdata"
  newart.keywords = tags
  newart.title = "Testdata #{tags}"
  thetime = Time.at(1112488002 + rand(155952185))
  newart.created_at = thetime
  newart.author = 'test import'
  newart.published = true
  newart.published_at = thetime
  newart.state = 'published'
  newart.save
}

end

end
