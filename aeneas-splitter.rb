require "json"
require "fileutils"

# Ugh. I feel like it's so ghetto to actually have to just straight up call an
# extra utility. And ffmpeg's / bash's argument style always feels like the
# worst arcane runes. I really ought to go build an rubyesque wrapper for this
# in the spirit of ffmpeg-python.

def trim(input_file, start_time, end_time, output_file)
  system "ffmpeg -loglevel error -i \"#{input_file}\" -ss #{start_time - 0.1} -to #{end_time} -c copy -map 0 \"#{output_file}\" -y"
end

timings_folder = "aeneas-verse-timings"
audio_chapters = "audio-chapters"

Dir.foreach(audio_chapters) do |audio_chapter|
  next unless audio_chapter.include? ".mp3"

  input_file = "#{audio_chapters}/#{audio_chapter}"

  chapter = audio_chapter.split(" ").map do |word|
    next "1" if word == "I"
    next "2" if word == "II"
    next "3" if word == "III"
    word
  end

  chapter = chapter.join(" ")

  book_index = chapter.split(" ")[0]
  book_name = chapter.split(".")[0].split(" ")[1..-2].join(" ")
  chapter = chapter.split(".")[0].split(" ")[1..-1].join(" ")

  timings_path = "#{timings_folder}/#{book_index} #{book_name}/#{chapter}.json"

  timings = JSON.parse(open(timings_path, "r").read())["fragments"]

  path = "aeneas-verses/#{book_index} #{book_name}/#{chapter}"
  FileUtils.mkdir_p path

  timings.each_with_index do |timing, index|
    next if index == 0 # first is blank / not a real verse
    verse = "#{chapter} #{(index).to_s.rjust(3, "0")}"
    output_file = "#{path}/#{verse}.mp3"
    trim(input_file, timing["begin"].to_i, timing["end"].to_i, output_file)
  end
end