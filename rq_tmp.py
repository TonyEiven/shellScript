#!/usr/bin/env python

from rq import Queue
from redis import Redis
from somewhere import count_words_at_url

redis_conn = Redis()
q = Queue(connection=redis_conn)

job = q.enqueue(count_words_at_url, 'http://www.baidu.com')
print job.result

time.sleep(2)
print job.result
