# Verse-Timings

This is a script that creates verse-timings for the KJV of the Bible. It uses
gently and requires that you have Docker installed.

```
docker pull lowerquality/gentle
docker run -P lowerquality/gentle
gem install kj
ruby verse-timings.rb
```

This script will of course take a very long time to run through the entire
Bible. In fact, as I'm writing this, the program is only part-way through
Leviticus, but it does seem to work fine.

I hope this code and / or the timings are helpful to you. Thank you.

TODO:

* Set this up as a proper gem (may be tricky because this requires docker and
gentle to run)
* Finish running this so that it gets all the verse timings (Up to Numbers now!)
* Generalize the script so that it can run with different versions of the bible
(and maybe other texts split up into verses?) and other audio files.
* Also it would probably be best if this script had options to work over
individual chapters.
* It'd be cool to get all the verse timings and audio well organized in a 
database and wrapped into a gem, sort of like the Kj library itself, but with
audio bibles, too.
