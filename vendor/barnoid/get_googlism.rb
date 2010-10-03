class GetGoogleism

require 'rubygems'
require 'json'
require 'net/http'
require 'cgi'

verbose = false
quiet = false

KEEP = 200
CACHEFILE = "googlism-cache"

results = {}
urls = {}
date = Time.now.strftime("%Y%m%d")

# read cache
File.open(CACHEFILE) do |file|
  file.each do |line|
    splitline = line.split('<>')
    results[splitline[0]] = splitline[2]
    urls[splitline[0]] = splitline[1]
  end
end


verbs =  ['is', 'was', 'can', 'should', 'shall', 'will', 'thinks', 'says', 'does', 'keeps', 'won']
verbs = verbs + ["isn't", "wasn't", "can't", "shouldn't", "won't"]

@site = Net::HTTP.new("ajax.googleapis.com", 80)

verb = verbs[rand(verbs.length)]
start = rand(6) * 8

url = "/ajax/services/search/web?v=1.0&q=\"barney+#{verb}\"&rsz=large&start=#{start}"
puts url if verbose
puts if verbose

response = @site.get(url, 'User-Agent' => "getgoogleism (Ruby Net::HTTP)", 'Referer' => "http://barnoid.org.uk/")
data = JSON.parse(response.body)

p data if verbose
puts if verbose

data['responseData']['results'].each { |result|
  content = result['content']
  content = CGI.unescapeHTML(content.gsub(/<\/?[^>]*>/, "")) # De-HTML
  content.gsub!(/\s(\s+)/, " ") # collapse multiple whitespace
  content.gsub!(/“|”/, "\"") # sexed quotes to unsexed
  content.gsub!(/&middot;/, "-") # &middot; seems to turn up
  puts content if verbose
  while mat = /(barney #{verb} .+?(!+|\?+|\. |\.\.\.|$))/i.match(content) do
    bis = mat.to_s
    bis.gsub!(/\s+$/, "") # remove trailing whitespace
    # discard the ones ending ...
    if /\.\.\.$/.match(bis) then
	  content = mat.post_match
      next
    end
    # match unmatched quotes
    if mat.to_s.scan(/"/).size % 2 != 0 then
      if mat.pre_match.scan(/"/).size % 2 != 0 then
        bis = "\"#{bis}"
      else
        bis = "#{bis}\""
      end
    end
    # match unmatched brackets
    brackets = bis.scan(/\(/).size - bis.scan(/\)/).size
    if brackets < 0 then
      bis = ("(" * brackets.abs) + bis
    elsif brackets > 0 then
      bis = bis + (")" * brackets)
    end
    puts "|#{bis}|" if not quiet
    results[bis] = date
    puts result["unescapedUrl"].gsub(/<>/, "") if not quiet
    urls[bis] = result["unescapedUrl"].gsub(/<>/, "")
    puts if not quiet
    content = mat.post_match
  end
}


#make list ordered by date
list = []
results.each do |key, value|
  list << [key, value]
end
list.sort! { |a,b| b[1] <=> a[1] }

#write out first KEEP entries
File.open(CACHEFILE, 'w') do |file|
  list[0, KEEP].each do |item|
    file.puts "#{item[0]}<>#{urls[item[0]]}<>#{item[1]}"
  end
end

end
