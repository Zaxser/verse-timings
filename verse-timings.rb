# Splitting up the text wasn't even necessary. Just putting the text with the
# sound into Gentle's GUI worked pretty well. Now we need to figure out how to
# automate the REST calls.
# The curl command that exists in gentle's readme on github doesn't do anything,
# but if you dig a bit, there's an example's folder, with a single line, which,
# with a little adjustment becomes:
# curl -X POST -F 'audio=@audio-chapters/01 Genesis 001.mp3' -F 'transcript=@text-chapters/genesis1.txt' 'http://localhost:49154/transcriptions?async=false' 
# Which works fantastically. All I have to do is adjust it into a faraday
# request.

require "kj"
require "faraday"
require "json"
require "fileutils"
require "mp3info"
require "humanize"

# Gentle's readme says the localhost is on 8765; it lied.
url = "http://localhost:49153"


conn = Faraday.new(url: url) do |faraday|
  faraday.request :multipart #make sure this is set before url_encoded
  faraday.adapter :net_http
end

Dir.foreach("audio-chapters").each do |audio_chapter|
  next if audio_chapter == "." or audio_chapter == ".."
  
  book_name = audio_chapter.split(" ")[1...-1].join(" ")
  chapter = audio_chapter.split(" ")[-1].split(".")[0].to_i

  # Getting rid of Roman Numerals is always more complicated than you think.
  chapter = audio_chapter.split(" ").map do |word|
    next "1" if word == "I"
    next "2" if word == "II"
    next "3" if word == "III"
    word
  end

  book_name = words.join(" ")
  book = Kj::Book.from_name_or_number(book_name)

  book_id = "#{book.id.to_s.rjust(2, "0")} #{book_name}"
  FileUtils.mkdir_p "text-chapters/#{book_id}"
  FileUtils.mkdir_p "verse-timings/#{book_id}"
    
  audio_filepath = "audio-chapters/#{audio_chapter}"

  path = "#{book_id}/#{book_name} #{chapter.to_s.rjust(3, "0")}"
  
  text_filepath = "text-chapters/#{path}.txt"
  verse_timings_filepath = "verse-timings/#{path}.json"

  chapter_number = chapter
  chapter = book.chapter(chapter)
  # Write the chapter to a text file so it can be used by Gentle
  file = open(text_filepath, "w") do |f|
    text = chapter.verses.inject("") {|t, v| t + v.text + "\n"}
    f.write(text)
  end
  
  # Set up the pay load for gentle
  payload = {
    audio: Faraday::UploadIO.new(audio_filepath, "audio/mp3"),
    transcript: Faraday::UploadIO.new(text_filepath, "text/txt")
  }

  # Get the timings back
  begin
    word_timings = conn.post('/transcriptions?async=false', payload).body
  rescue
    # This seems to die on Psalm 119. :(
    puts [audio_filepath, text_filepath]
    next
  end

  word_timings = JSON.parse(word_timings)["words"]

  # Convert word timings to verse timings
  first_word_index = 0
  verse_timings = []
  chapter.verses.each do |verse|
    length = verse.text.split(" ").length
    last_word_index = first_word_index + length - 1
    words = word_timings[first_word_index..last_word_index]

    offset = 1 # if gentle won't give us the time, get the next time
    until words[0]["start"] or offset >= first_word_index
      words[0]["start"] = word_timings[first_word_index - offset]["end"]
      offset += 1
    end

    # if all else fails, send it to the start of the file
    unless words[0]["start"] 
      words[0]["start"] = 0 
      p audio_chapter, verse.number
    end

    offset = 1 # if gentle won't give us the time, get the next time
    until words[-1]["end"] or last_word_index + offset >= word_timings.length
      words[-1]["end"] = word_timings[last_word_index + offset]["start"]
      offset += 1
    end

    unless words[-1]["end"] # if all else fails, send it to the end of the file
      Mp3Info.open(audio_filepath) do |mp3| 
        words[-1]["end"] = mp3.length
        p mp3.length, audio_chapter, verse.number
      end
    end
    
    verse_timing = {
      "book": book.name,
      "chapter": chapter.number,
      "verse": verse.number,
      "start": words[0]["start"],
      "end": words[-1]["end"]
    }
    verse_timings.append(verse_timing)
    first_word_index = last_word_index + 1
  end

  file = open(verse_timings_filepath, "w") do |f|
    f.write(JSON.pretty_generate(verse_timings))
  end
end