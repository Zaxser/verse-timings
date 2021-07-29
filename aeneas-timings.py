from aeneas.executetask import ExecuteTask
from aeneas.task import Task
from os.path import abspath
import aeneas

# create Task object
config_string = u"task_language=eng|is_text_type=plain|os_task_file_format=json"
task = Task(config_string=config_string)
task.audio_file_path_absolute = abspath(u"audio-chapters/01 Genesis 002.mp3")
task.text_file_path_absolute = abspath(u"text-chapters/01 Genesis/Genesis 002.txt")
task.sync_map_file_path_absolute = abspath(u"gen2-syncmap.json")

# process Task
ExecuteTask(task).execute()

# output sync map to file
task.output_sync_map_file()