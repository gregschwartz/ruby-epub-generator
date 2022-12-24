require 'rubygems'
require 'mechanize'
require 'gepub'

def cleanHTML(html)
  html.gsub!(/<hr [^\/>]+>/, "<hr \/>")

  return html
end

def addChapter(chapterNumber, title, content)
  content = "<html xmlns='http://www.w3.org/1999/xhtml'><body>" + cleanHTML(content) + "</body></html>"

  book.add_item("text/chap#{chapterNumber}.xhtml").add_content(StringIO.new(content)).toc_text(title).landmark(type: "bodymatter", title: title)
end

urls = [
  "https://www.reddit.com/r/redditserials/comments/n1duqa/leveling_up_the_world_adventure_arc_chapter_119/"
]


#filename is the date and time
dateAsString = Time.new.strftime("%Y-%m-%d_%H-%M-%S")

book = GEPUB::Book.new
book.primary_identifier('http://gregschwartz.net', dateAsString, 'URL')
book.language = 'en'

book.add_title "Subscriptions #{dateAsString}",
               title_type: GEPUB::TITLE_TYPE::MAIN,
               lang: 'en',
               file_as: "Greg's Subscriptions",
               display_seq: 1

book.add_creator 'Greg',
                 display_seq:1

#web connection
a = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

#add items
book.ordered do
  #weird structural way of doing it from the examples
  book.add_item('text/cover.xhtml',
                content: StringIO.new(<<-COVER)).landmark(type: 'cover', title: 'cover page')
                <html xmlns="http://www.w3.org/1999/xhtml">
                <head>
                  <title>cover page</title>
                </head>
                <body>
                <h1>#{dateAsString}</h1>
                </body></html>
  COVER

  chapterNumber = 1
  urls.each do |url|
    #load the URL, and loop if there is a Next link
    loop do
      puts "Load #{url}"
      a.get(url) do |page|
        title = page.title
        contentDiv = page.search(".RichTextJSON-root")

        addChapter(chapterNumber, title, contentDiv.map{|elt| elt.to_s}.first)
        nextLink = contentDiv.search("a")

        puts "\tAdded as chapter"
      end

      chapterNumber += 1
      sleep(rand(2))


      break unless nextLink
    end #loop
  end #urls.each
end #book.ordered

epubname = File.join(File.dirname(__FILE__), dateAsString + ".epub")

book.generate_epub(epubname)
