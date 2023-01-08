require 'rubygems'
require 'json'
require 'mechanize'
require 'gepub'

URL_STORAGE = "urls.json"
wordsToConsiderNext = ["Next"]#, ">", "Continue"]

def cleanHTML(html)
  html.gsub!(/<hr [^\/>]+>/, "<hr \/>")
  html.gsub!(/<br [^\/>].>/, "<br \/>")
  html.gsub!(/<br>/, "<br \/>")
  html.gsub!(/,/,',')
  html.gsub!(/…/,'&#8230;')
  html.gsub!(/★/,'&#9733;')

  html.gsub!(/‘/,'&apos;')
  html.gsub!(/’/,'&apos;')
  html.gsub!(/“/,'&quot;')
  html.gsub!(/”/,'&quot;')
  html.gsub!(/—/,'&#8212;')
  html.gsub!(/—/,'&#8212;')
  html.gsub!(/•/,'&#8226;')
  html.gsub!(/·/,'&#8901;')
  html.gsub!(/•/,'&#8226;')
  html.gsub!(/◦/,'&#9702;')
  html.gsub!(/∙/,'&#8729;')
  html.gsub!(/‣/,'&#8227;')
  html.gsub!(/⁃/,'&#8259;')
  html.gsub!(/°/,'&#176;')
  html.gsub!(/∞/,'&#8734;')
  html.gsub!(/™/,'&#8482;')
  html.gsub!(/©/,'&#169;')

  html.gsub!(/«/,'&laquo;')
  html.gsub!(/»/,'&raquo;')
  html.gsub!(/‹/,'&lsaquo;')
  html.gsub!(/›/,'&rsaquo;')

  return html
end

##### Load stored URLs from last time
begin
  rawInput = File.read(URL_STORAGE)
rescue Errno::ENOENT
  puts "File #{URL_STORAGE} not found. Please create it."
  return
rescue Errno::EACCES
  puts "Insufficient permissions, not allowed to open file #{URL_STORAGE}."
  return
rescue => r
  puts "Error loading #{URL_STORAGE}: #{r}"
  return
end
unless rawInput && rawInput.length > 0
  puts "Error, cannot find file #{URL_STORAGE} or is empty"
  return
end

begin
  urls = JSON.parse(rawInput)
rescue JSON::ParserError
  puts "File #{URL_STORAGE} isn't valid JSON"
  return
rescue r
  puts "Error parsing #{URL_STORAGE} into JSON: #{r}"
  return
end
unless urls && urls.length > 0
  puts "Error, file #{URL_STORAGE} is empty"
  return
end


#### Overrides
isFirstTimeRunning = true
urls = [
  # "https://www.reddit.com/r/HFY/comments/z37kbd/the_great_erectus_and_faun_romance/", #last one, no next link

  #already caught up on
  # "https://www.reddit.com/r/HFY/comments/xsmwaa/the_great_erectus_and_faun_poop_and_circumstance/",
  # "https://www.reddit.com/r/HFY/comments/xsux21/eagle_springs_stories_truthseeker_chapter_0/",
  # "https://www.reddit.com/r/HFY/comments/xsxome/dungeon_tour_guide_ch_24/",
  # "https://www.reddit.com/r/HFY/comments/ynuook/we_need_a_deathworlder_pt51/",
  # "https://www.reddit.com/r/HFY/comments/xu3y50/of_men_and_dragons_book_3_chapter_15/",
  # "https://www.reddit.com/r/HFY/comments/xu6mfj/transferred_chapter_16/",
  # "https://www.reddit.com/r/HFY/comments/xukozz/the_nature_of_predators_51/",
  # "https://www.reddit.com/r/HFY/comments/xutaig/finding_posella_34/",
  # "https://www.reddit.com/r/HFY/comments/xzyl2l/gods_saviors_people_part_20_a_journey_of_a/",
  # "https://www.reddit.com/r/HFY/comments/xz9u43/humans_dont_make_good_familiars_book_2_part_18/",
  # "https://www.reddit.com/r/HFY/comments/xy2q3u/no_simple_beast_episode_6/",
  # "https://www.reddit.com/r/HFY/comments/xx461i/eagle_springs_stories_testing_the_waters_part_2/",
  # "https://www.reddit.com/r/HFY/comments/xx3ldo/extermination_order_23_hunters_shutins_and/",
  # "https://www.reddit.com/r/HFY/comments/xwn2pq/a_teenage_death_commando_goes_to_school_the_final/",
  # "https://www.reddit.com/r/HFY/comments/xvfr98/a_job_for_a_deathworlder_chapter_83/",
  # "https://www.reddit.com/r/HFY/comments/y532g6/tales_from_the_terran_republic_demonstrations/",
  # "https://www.reddit.com/r/HFY/comments/y3fj6f/hallows_8_the_disturbance/"

  #live series

  #not on reddit, but try
  #"https://theyaresmol.com/smolive-garden-chapter-16-the-absolute-and-most-correct-choice/",

  #huge series
  # "https://www.reddit.com/r/redditserials/comments/n1duqa/leveling_up_the_world_adventure_arc_chapter_119/",

  #only for testing "no next link"
  # "https://www.reddit.com/r/HFY/comments/z37kbd/the_great_erectus_and_faun_romance/", #last one, no next link

  #just testing
  # "https://www.reddit.com/r/HFY/comments/z37kbd/the_great_erectus_and_faun_romance/",
  # "https://www.reddit.com/r/HFY/comments/xyu1ak/dungeon_tour_guide_ch_29/"
]

#not working because the next link is in the fucking comments as PART [n+1], can I simply compare them and take the maximal one? e.g. if current=2, prev="Part 1" next="Part 3"
#https://www.reddit.com/r/HFY/comments/yo2eit/bone_music_chapter_one/
#https://www.reddit.com/r/HFY/comments/ynuook/we_need_a_deathworlder_pt51/
# https://www.reddit.com/r/HFY/comments/y6r3mo/by_the_book/
# https://www.reddit.com/r/HFY/comments/zb40ro/a_broken_machine/

#probably can't figure out how to recognize this silly next structure
# "https://www.reddit.com/r/HFY/comments/ynwoiw/those_who_walk_the_earth_pt_1_of_2/"
# "https://www.reddit.com/r/HFY/comments/yp7csr/those_who_walk_the_earth_pt_2_of_2/"


###########

urlsToStoreAndCheckNextTime = []

#filename is the date and time
dateForFilename = Time.new.strftime("%m-%d-%H-%M")
dateForTitle = Time.new.strftime("%m/%d %H:%M")

book = GEPUB::Book.new
book.primary_identifier('http://gregschwartz.net', dateForFilename, 'URL')
book.language = 'en'
book.add_title("Subscriptions #{dateForTitle}", title_type: GEPUB::TITLE_TYPE::MAIN, lang: 'en', file_as: "Greg's Subscriptions", display_seq: 1)
book.add_creator 'Greg',
                  display_seq: 1

#make sure the words are lowercase
wordsToConsiderNext.map!{|w| w.downcase}

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
                <h1>#{dateForTitle}</h1>
                </body></html>
  COVER

  seriesNumber = 0
  urls.each do |url|
    #normally the stored URL was the last one we read, so we don't want to include it
    addToExport = true #false
    ###### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ###### TODO: remove isFirstTimeRunning and overriding urls !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ###### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    #load the URL, and loop if there is a Next link
    puts "\nSeries: #{url}"
    chapterNumber = 1
    a.get(url) do |page|
      loop do #loop to iterate on this URL and "next" pages
        puts "\tPage: #{page.uri}"

        if (addToExport)
          title = page.title

          content = cleanHTML(page.at(".RichTextJSON-root").to_s)
          contentWrapped = "<html xmlns='http://www.w3.org/1999/xhtml'><body><h1>"+ title +"</h1><p><a href='#{page.uri}'>#{page.uri}</a></p>" + content + "</body></html>"

          book.add_item("text/s#{seriesNumber}/ch#{chapterNumber}.xhtml").add_content(StringIO.new(contentWrapped)).toc_text(title).landmark(type: "bodymatter", title: title)

          puts "\t\tAdded as chapter (#{content.length} chars)"
        end

        #### Look for link to next story in series
        nextLink = nil
        links = page.links #because Mechanize SUCKS and cannot narrow down links further, argh
        links.each do |link|
          #see if any of the wordsToConsiderNext appear in the link text
          if wordsToConsiderNext.select{|word| link.text.downcase.match(word)}.length > 0 && link.text != "The Next Best Hero" #specific badly named link
            #puts "\tNext link: #{link.href}"
            nextLink = link
            break
          end
        end
        break unless nextLink

        chapterNumber += 1
        sleep(1 + rand(3))

        #testing
        break if chapterNumber > 30

        #click on next link and repeat to grab
        page = nextLink.click

        #now we include every page we process
        addToExport = true
      end #loop

      #store current URL as the one to start with next time
      urlsToStoreAndCheckNextTime.push(page.uri)
      # puts "\tSaved URL for next time: #{page.uri}"

      seriesNumber += 1
    end #a.get(url)
  end #urls.each
end #book.ordered

#Store URLs to disk
File.open(URL_STORAGE,"w") { |f| f.write(urlsToStoreAndCheckNextTime.to_json) }

#Output epub
epubname = File.join(File.dirname(__FILE__), "Stories " + dateForFilename + ".epub")
book.generate_epub(epubname)
puts "✅ ePub exported!\n"
