require 'flickr/flickr'

class Typo
  class Textfilter
    class List < TextFilterPlugin::MacroPost
      plugin_display_name "List"
      plugin_description "Generate lists based on criteria"

      def self.help_text
        %{
You can use `<typo:list>` to display lists of articles with a particular tag or category. Example:

    <typo:list tag="thing" num="10" body="10"/>

Produces a list of the 10 most recent articles tagged with "thing" along with the first 10 words from
the article's body.

This macro takes a number of parameters:

* **tag** Tag to list.
* **cat** Category to list.
* **num** Number of articles to list.
* **body** Number of words of body to list.
* **class** Class attribute to pass to the <ul> tag.
* **excerpt** Whether to include the contents of excerpt.
}
      end

      def self.macrofilter(blog,content,attrib,params,text="")
	    tag     = attrib['tag']
		cat     = attrib['cat']
		num     = attrib['num'] || "10"
		cls     = attrib['class']
		body	= attrib['body']
		excerpt	= attrib['excerpt']

        if cls then
		  cls = " class=\"#{cls}\""
		else
		  cls = ""
		end

        if tag then
          arts = Tag.get(tag).published_articles
		elsif cat then
		  arts = Category.find_by_name(cat).published_articles
		else
		  arts = Article.find_published
        end

        out = "<ul#{cls}>\n"
		arts[0,num.to_i].each { |art|
		  out << "<li>"
		  if art.class.to_s == "FlickrPic" then
            flic = FlickrCache.get(art.permalink, "square")
            out << "<img src=\"#{flic[0]}\" width=\"#{flic[2]}\" height=\"#{flic[3]}\"/>"
          end
		  out << "<a class=\"title\" href=\"#{art.permalink_url}\">#{art.title}</a>"
		  if excerpt and art.excerpt != "" then
		    out << "<p>#{art.excerpt}</p>"
		  end
          if body then
		    text = art.body
		    text.gsub!(/\/h[1-9]|\/p|\/li/,'br/')
		    text = sanitize(text, :tags => %w(i b em strong br)).split
            out << "<p>#{text[0,body.to_i].join(" ")}#{if body.to_i < text.length then " ..." end}</p>"
          end
		  out << "</li>\n"
		}
		out << "</ul>\n"
		return out
      end

    end
  end
end
