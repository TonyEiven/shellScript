#!/usr/bin/env python

import pyinotify

multi_event = pyinotify.IN_CREATE

wm = pyinotify.WatchManager()

class MyEventHandler(pyinotify.ProcessEvent):
	def process_IN_CREATE(self,event):
		print('CREATE',event.pathname)

handler = MyEventHandler()
notifier = pyinotify.Notifier(wm,handler)

wm.add_watch('/tmp',multi_event)
notifier.loop()