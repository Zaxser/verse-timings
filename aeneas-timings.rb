require "pycall/import"
require "kj"
require "json"
require "fileutils"
require "humanize"

include PyCall::Import

# Using the Aeneas library because Gentle would sometimes timeout on long
# chapters. There IS a windows downloader for aeneas, but it messes up PyCall,
# and then I tried a VirtualBox, but Lubuntu starts with Python2, which messes
# up pip. Eventually I got this working with WSL, but Jesus H that was a big
# yak just to get bible verses split up.

aeneas = PyCall.import_module("aeneas")
pyfrom("aeneas.executetask", import: :ExecuteTask)
pyfrom("aeneas.task", import: :Task)

# create Task object
config_string = "task_language=eng|is_text_type=plain|os_task_file_format=json"

Dir.foreach("audio-chapters").each do |audio_chapter|
  next unless audio_chapter.include? ".mp3"
  
  book_name = audio_chapter.split(" ")[1...-1].join(" ")
  chapter = audio_chapter.split(" ")[-1].split(".")[0].to_i

  # Getting rid of Roman Numerals is always more complicated than you think.
  words = book_name.split(" ").map do |word|
    next "1" if word == "I"
    next "2" if word == "II"
    next "3" if word == "III"
    word
  end

  book_name = words.join(" ")
  book = Kj::Book.from_name_or_number(book_name)

  book_id = "#{book.id.to_s.rjust(2, "0")} #{book_name}"
  FileUtils.mkdir_p "text-chapters/#{book_id}"
    
  audio_filepath = "audio-chapters/#{audio_chapter}"
  path = "#{book_id}/#{book_name} #{chapter.to_s.rjust(3, "0")}"
  text_filepath = "text-chapters/#{path}.txt"
  verse_timings_filepath = "aeneas-verse-timings/#{path}.json"

  chapter_number = chapter
  chapter = book.chapter(chapter)

  # Write the chapter to a text file so it can be used by Gentle
  file = open(text_filepath, "w") do |f|
    text = ""
    if chapter_number == 1
      text += "The Holy Bible: The King James Version, Read by Alexander Scourby"
    end
    text += " Chapter " + chapter_number.humanize + "\n"
    text += chapter.verses.inject("") {|t, v| t + v.text + "\n"}
    f.write(text)
  end

  task = Task.new(config_string:config_string)
  task.audio_file_path_absolute = File.expand_path(audio_filepath)
  task.text_file_path_absolute = File.expand_path(text_filepath)
  task.sync_map_file_path_absolute = File.expand_path(verse_timings_filepath)

  # process Task
  ExecuteTask.new(task).execute()

  # output sync map to file
  task.output_sync_map_file()
end