# REQUIREMENTS: npm install -g mammouth
# USAGE: Files must have a .mammouth suffix

import sublime, sublime_plugin,os
from os.path import dirname, realpath

class BuildMammouthOnSave(sublime_plugin.EventListener):
 
  def on_post_save(self, view):
    mammouthFile = view.file_name()
    filename, file_extension = os.path.splitext(mammouthFile)
    if file_extension == ".mammouth" or file_extension == ".mmt":
      print("Compiling: " + mammouthFile)
      view.window().run_command('exec',{'cmd': ["/usr/local/bin/mammouth", "-c", mammouthFile] })

# REFERENCES
# http://www.purplebeanie.com/Development/automatically-run-build-on-save-in-sublime-text-2.html