import ffmpeg

name = ""
audio = ffmpeg.input("audio-chapters/" + "01 Genesis 001" + ".mp3")

ffmpeg.output(audio, "01 Genesis 001" + ".mp3").run()