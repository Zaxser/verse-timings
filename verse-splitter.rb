require "json"
require "fileutils"

# Ugh. I feel like it's so ghetto to actually have to just straight up call an
# extra utility. And ffmpeg's / bash's argument style always feels like the
# worst arcane runes. I really ought to go build an rubyesque wrapper for this
# in the spirit of ffmpeg-python.

def trim(input_file, start_time, end_time, output_file)
  system "ffmpeg -i \"#{input_file}\" -ss #{start_time - 0.1} -to #{end_time} -c copy -map 0 \"#{output_file}\""
end

Dir.foreach("verse-timings").map {|fn| fn.split(".")[0]}.each do |chapter|
  next unless chapter

  timings = JSON.parse(open("verse-timings/#{chapter}.json", "r").read())

  input_file = "audio-chapters/#{chapter}.mp3"

  timings.each do |timing|
    book = timing["book"]
    chapter = timing["chapter"]
    verse = "#{book} #{chapter} #{timing["verse"]}"
    path = "audio-verses/#{book}/#{chapter}"
    FileUtils.mkdir_p path
    output_file = "audio-verses/#{book}/#{chapter}/#{verse}.mp3"
    p timing["start"]
    trim(input_file, timing["start"], timing["end"], output_file)
  end
end

