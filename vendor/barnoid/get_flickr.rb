class GetFlickr
  require 'net/http'
  require 'digest/md5'
  require 'xmlsimple'
  require 'time'

#  API_KEY = ""
#  SECRET = ""
#  TOKEN = ""

  require 'flickr_api_data'

  URL_DOMAIN = "api.flickr.com"
  URL_BEGIN = "/services/rest/"
  USERAGENT = "barnoid.org.uk updater (Ruby Net::HTTP)"

  def self.updatePic(id)
    id = id.to_s
    info = self.getinfo(id)
    art = Article.find_or_initialize_by_permalink("flickr_#{id}")
    art.title = info['title'].to_s
    if art.title == "" then
      art.title = "Untitled on Flickr"
    end
    art.excerpt = "<a href=\"/#{art.permalink}\"><img src=\"#{getsource(id, "Small")}\" alt=\"#{info['title']}\"/></a>"
    if info['media'] == "video" then
      art.body = "<div class=\"flickr_pic\"><object type=\"application/x-shockwave-flash\" width=\"640\" height=\"480\" data=\"http://www.flickr.com/apps/video/stewart.swf?v=71377\" classid=\"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000\"> <param name=\"flashvars\" value=\"intl_lang=en-us&photo_secret=#{info['secret']}&photo_id=#{id}&hd_default=true\"></param> <param name=\"movie\" value=\"http://www.flickr.com/apps/video/stewart.swf?v=71377\"></param> <param name=\"bgcolor\" value=\"#000000\"></param> <param name=\"allowFullScreen\" value=\"true\"></param><embed type=\"application/x-shockwave-flash\" src=\"http://www.flickr.com/apps/video/stewart.swf?v=71377\" bgcolor=\"#000000\" allowfullscreen=\"true\" flashvars=\"intl_lang=en-us&photo_secret=#{info['secret']}&photo_id=#{id}&hd_default=true\" height=\"480\" width=\"640\"></embed></object></div>"
    else
      art.body = "<div class=\"flickr_pic\"><a href=\"#{info['urls']['url']['content']}\"><img src=\"#{getsource(id, "Medium 640")}\" alt=\"#{info['title']}\"/></a></div>"
    end
    art.body << "<div class=\"flickr_desc\">#{info['description']}</div>"
    art.keywords = info['tags_s']
    art.created_at = Time.parse(info['dates']['taken'])
    art.author = 'barnoid'
    art.user_id = 1
    art.published = true
    art.published_at = Time.at(info['dates']['posted'].to_i)
    art.state = 'published'
    art.extended = self.exiftable(id)
    if info.has_key?('location') then
      g = art.geotag
  	  if g.nil? then
        g = Geotag.new
      end
      g.lat = info['location']['latitude'].to_f
      g.lon = info['location']['longitude'].to_f
      g.accuracy = info['location']['accuracy'].to_i
      locname = ""
      locname << info['location']['locality']['content'] + ", " if info['location'].has_key?('locality')
      locname << info['location']['county']['content'] + ", " if info['location'].has_key?('county')
      locname << info['location']['region']['content'] + ", " if info['location'].has_key?('region')
      locname << info['location']['country']['content'] if info['location'].has_key?('country')
      g.name = locname
      g.save
      art.geotag = g
    end
    art.save
    p art
    cat = Category.find_by_name('Flickr')
    if not art.categories.member?(cat) then
      art.categories << cat
      art.save
    end
  end

  def self.updatePics
    blog = Blog.default
    puts "Last update was: #{Time.at(blog.settings['flickr_update']).to_s}"
    page = 1
    pages = 1
    while (page <= pages) do
      url = self.makeurl('api_key' => API_KEY,
                         'auth_token' => TOKEN,
                         'method' => 'flickr.photos.recentlyUpdated',
                         'per_page' => '100',
                         'page' => page.to_s,
                         'min_date' => blog.settings['flickr_update'].to_s)
      updatepics = self.fetch(url)
      if updatepics['stat'] == "ok" then
        pages = updatepics['photos']['pages'].to_i
        total = updatepics['photos']['total'].to_i
        puts "Total: #{total} Pages: #{pages} Page: #{page}"
        if total == 0 then
          puts "None to update"
        elsif total == 1 then
          puts "Updating: 1"
          puts "#{updatepics['photos']['photo']['id']} #{updatepics['photos']['photo']['title']}"
          if (updatepics['photos']['photo']['ispublic'] == '1') then
            self.updatePic(updatepics['photos']['photo']['id'])
          else
            puts "  is private"
          end
          puts
        else
          puts "Updating: #{updatepics['photos']['photo'].size}"
          updatepics['photos']['photo'].each { |photo|
            puts "#{photo['id']} #{photo['title']}"
            if (photo['ispublic'] == '1') then
              self.updatePic(photo['id'])
              sleep 1
            else
              puts "  is private"
            end
            puts
          }
        end
      else
        puts "Flickr API error"
        p updatepics
      end
      page = page + 1
      sleep 2
    end
    blog.settings['flickr_update'] = Time.now.to_i
    blog.save
  end


  private

  def self.getinfo(id)
    info = self.fetch(URL_BEGIN + '?api_key=' + API_KEY + '&method=flickr.photos.getInfo&photo_id=' + id)['photo']
    tags = ""
    if info['tags'].has_key?('tag') then
      if info['tags']['tag'].kind_of?(Array) then
        info['tags']['tag'].each { |tag| tags << tag['content'] + ' ' }
      else
        tags = info['tags']['tag']['content']
      end
    end
    info['tags_s'] = tags
    return info
  end

  def self.getsource(id, reqsize)
    urls = self.fetch(URL_BEGIN + '?api_key=' + API_KEY + '&method=flickr.photos.getSizes&photo_id=' + id)['sizes']
    source = ""
    urls['size'].each { |size|
      source = size['source'] if size['label'] == reqsize  
    }
    return source
  end

  def self.getexif(id)
    exif = self.fetch(URL_BEGIN + '?api_key=' + API_KEY + '&method=flickr.photos.getExif&photo_id=' + id)['photo']
  end

  def self.exiftable(id)
    #exif tags to use, 0 is use raw value, 1 is use clean
    exif_tags = { 'Make' => 0,  
                  'Model' => 0,
                  'DateTimeOriginal' => 0,
                  'ExposureTime' => 1,
                  'FNumber' => 1,
                  'ExposureProgram' => 1,
                  'ISO' => 0,
                  'ExposureCompensation' => 1,
                  'MeteringMode' => 0,
                  'Flash' => 0, 
                  'FocalLength' => 1,
                  'LensType' => 0,
                  'CameraTemperature' => 0,
                  'Quality' => 0,
                  '271' => 0, #make
                  '272' => 0, #model
                '36867' => 0, #date and time
                '33434' => 1, #exposure
                '33437' => 1, #aperture
                '34850' => 1, #exposure program
                '34855' => 0, #iso
                '37380' => 1, #exposure bias
                '37383' => 1, #metering mode
                '37385' => 1, #flash
                '37386' => 1, #focal length
                  '149' => 0 #lens
              }

    exif = getexif(id)
    if not exif.has_key? "exif" then return "" end
    exif = exif['exif']
    etable = {}
    c = 0
    exif.each { |etag|
      if exif_tags.has_key? etag['tag'] then
        if exif_tags[etag['tag']] == 0 then
          etable[etag['label']] = [c, etag['raw']]
        else
          if etag.has_key? 'clean' then
            etable[etag['label']] = [c, etag['clean']]
          else
            etable[etag['label']] = [c, etag['raw']]
          end
        end
        c += 1
      end
    }
    table = "<table class=\"exif_table\">\n"
    etable.keys.map{ |key| [etable[key][0], key] }.sort{ |x,y| x[0] <=> y[0] }.map{ |z| z[1] }.each { |label|
      table << "<tr><td>#{label}</td><td>#{etable[label][1]}</td></tr>\n"
    }
    table << "</table>\n"
    return table
  end
  

  #take a hash of parameters and build flickr API REST URL
  def self.makeurl(params)
    sigstr = ""
    url = URL_BEGIN + '?'
    params.keys.sort.each { |param|
      sigstr << param << params[param]
      url << param << '=' << params[param] << '&'
    }
    sigstr = SECRET + sigstr
    return url + 'api_sig=' + Digest::MD5.hexdigest(sigstr)
  end

  def self.fetch(url)
    site = Net::HTTP.new(URL_DOMAIN, 80)
    resp = site.get2(url, 'User-Agent' => USERAGENT)
    data = XmlSimple.xml_in(resp.body, { 'ForceArray' => false })
    return data
  end
  
end
