require "json"
require "fileutils"

# Ugh. I feel like it's so ghetto to actually have to just straight up call an
# extra utility. And ffmpeg's / bash's argument style always feels like the
# worst arcane runes. I really ought to go build an rubyesque wrapper for this
# in the spirit of ffmpeg-python.

def trim(input_file, start_time, end_time, output_file)
  system "ffmpeg -loglevel error -i \"#{input_file}\" -ss #{start_time - 0.1} -to #{end_time} -c copy -map 0 \"#{output_file}\" -y"
end


book_name = "01 Genesis"
Dir.foreach("verse-timings/#{book_name}").map {|fn| fn.split(".")[0]}.each do |chapter|
  next unless chapter

  timings = JSON.parse(open("verse-timings/01 Genesis/#{chapter}.json", "r").read())
  input_file = "audio-chapters/#{book_name} #{chapter.split(" ")[-1]}.mp3"

  path = "audio-verses/#{book_name}/#{chapter}"
  FileUtils.mkdir_p path

  timings.each do |timing|
    verse = "#{chapter} #{timing["verse"].to_s.rjust(3, "0")}"
    output_file = "audio-verses/#{book_name}/#{chapter}/#{verse}.mp3"
    trim(input_file, timing["start"], timing["end"], output_file)
  end
end

