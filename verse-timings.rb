# Splits up chapter text in the hopes that it can be digested by docker.
# Splitting up the text wasn't even necessary. Just putting the text with the
# sound into Gentle's GUI worked pretty well. Now we need to figure out how to
# automate the REST calls.
# The curl command that exists in gentle's readme on github doesn't do anything,
# but if you dig a bit, there's an example's folder, with a single line, which,
# with a little adjustment becomes:
# curl -X POST -F 'audio=@audio-chapters/01 Genesis 001.mp3' -F 'transcript=@text-chapters/genesis1.txt' 'http://localhost:49154/transcriptions?async=false' 
# Which works fantastically. All I have to do is adjust it into a faraday
# request.

require "Kj"
require "faraday"
require "json"



# One of these days I've got to figure out how to set up paths so that it
# doesn't matter where you open the script from: this will fail if you don't 
# run this from the scripts/ folder.

# Gentle's readme says the localhost is on 8765; it lied.
url = "http://localhost:49154"

conn = Faraday.new(url: url) do |faraday|
  faraday.request :multipart #make sure this is set before url_encoded
  faraday.adapter :net_http
end

Kj::Bible.new.books.each do |book|
  id = book.id.to_s.rjust(2, "0")
  book.chapters.each do |chapter|
    number = chapter.number.to_s.rjust(3, "0")
    text_filepath = "text-chapters/#{id} #{book.name} #{number}.txt"
    audio_filepath = "audio-chapters/#{id} #{book.name} #{number}.mp3"
    word_timings_filepath = "word-timings/#{id} #{book.name} #{number}.json"
    verse_timings_filepath = "verse-timings/#{id} #{book.name} #{number}.json"

    # Write the chapter to a text file so it can be used by Gentle
    file = open(text_filepath, "w") do |f|
      text = chapter.verses.inject("") {|t, v| t + "\n" + v.text}
      f.write(text)
    end
    
    # Set up the pay load for gentle
    payload = {
      audio: Faraday::UploadIO.new(audio_filepath, "audio/mp3"),
      transcript: Faraday::UploadIO.new(text_filepath, "text/txt")
    }

    # Get the timings back
    word_timings = conn.post('/transcriptions?async=false', payload).body

    file = open(word_timings_filepath, "w") do |f|
      f.write(word_timings)
    end

    # p JSON.parse(word_timings)
    word_timings = JSON.parse(word_timings)["words"]

    # Convert word timings to verse timings
    first_word_index = 0
    verse_timings = []
    chapter.verses.each do |verse|
      length = verse.text.split(" ").length
      words = word_timings[first_word_index...first_word_index + length]
      # p first_word_index, verse.text, words.map {|w| w["word"]}
      
      verse_timing = {
        "book": book.name,
        "chapter": chapter.number,
        "verse": verse.number,
        "start": words[0]["start"],
        "startOffset": words[0]["start"], # Not sure what this does, JIC
        "end": words[-1]["end"],
        "endOffset": words[-1]["endOffset"] # Not sure what this does, JIC
      }
      verse_timings.append(verse_timing)
      first_word_index += length
    end


    file = open(verse_timings_filepath, "w") do |f|
      f.write(JSON.pretty_generate(verse_timings))
    end
  end
end