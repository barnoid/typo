require 'net/http'
require 'uri'

class Typo
  class Textfilter
    class Embed < TextFilterPlugin::MacroPost
      plugin_display_name "Embed"
      plugin_description "Embed HTML from another site"

      def self.help_text
        %{
You can use `<typo:embed>` to embed HTML from a site. Example:

    <typo:embed href="http://blah.com/thing"/>

Embed HTML from the page at http://blah.com/thing

This macro takes a number of parameters:

* **href** URL to page to embed.
}
      end

      def self.macrofilter(blog,content,attrib,params,text="")
	    href = attrib['href']
        
		#out = ""
		out = params.inspect
		if href then
		  out << Net::HTTP.get(URI.parse(href))
        end
		return out
      end

    end
  end
end
