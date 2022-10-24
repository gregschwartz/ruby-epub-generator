require "epubber"

#input url list
puts "Enter URLs followed by two blank lines"
urls = gets("\n\n").chomp.split("\n")

#filename is the date and time
filename = Time.new.strftime("%Y-%m-%d_%H-%M-%S") +".epub"

#build the ePub file
current_dir = File.dirname(__FILE__)
path = Epubber.generate(working_dir: current_dir, filename: filename) do |b|
  b.title "My First EPUB book"
  b.author "Ramirez, Federico"
  b.url "https://beezwax.net"
  b.introduction do |i|
    i.content "<p>This is an introduction.</p>"
  end
  b.chapter do |c|
    c.title "Chapter 1"
    c.content "<p>This is some content!</p>"
  end
  b.chapter do |c|
    c.title "Chapter 2"
    c.content "<p>Some more content this is.</p>"
  end
end
puts "Book generated in #{path}"
