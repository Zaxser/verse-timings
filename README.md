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
