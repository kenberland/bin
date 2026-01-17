#!/usr/bin/env python
from datetime import datetime, timedelta
import os
import re
import sys
import time
from imapclient import IMAPClient
from pytz import timezone
import pytz
import logging
from daemonize import Daemonize


pid = "/tmp/remove-old-mail.py.pid"
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.propagate = False
fh = logging.FileHandler("/home/ken/remove-old-mail.py.log", "a+")
formatter = logging.Formatter("%(asctime)s;%(levelname)s;%(message)s")
fh.setLevel(logging.DEBUG)
fh.setFormatter(formatter)
logger.addHandler(fh)
keep_fds = [fh.stream.fileno()]
password = sys.stdin.read()
m = re.search(r"PASSWORD=(\w+)", password)
password = m.group(1)
localtime = timezone("America/Los_Angeles")

def run_once():
    logger.debug("run_once()")
    oldest_item = ( localtime.localize(datetime.now()) - timedelta(days=5)).strftime("%d-%b-%Y")
    server = IMAPClient('localhost', ssl=False, use_uid=True)
    server.login("mken", password)
    server.select_folder('INBOX')
    messages = server.search([b'NOT', u'FLAGGED', b'NOT', b'SINCE', oldest_item])
    server.set_flags(messages, b'\\Deleted', silent=False)
    logger.debug("%d messages " % len(messages))
    for msgid, data in server.fetch(messages, ['ENVELOPE']).items():
        envelope = data[b'ENVELOPE']
        logger.debug(f"removing #{envelope.date.isoformat()} #{msgid}, {envelope.subject.decode()}")
        server.uid_expunge(msgid)
    server.logout()

def loop():
    while True:
        run_once()
        logger.debug("Sleep...")
        time.sleep(86400)

daemon = Daemonize(app="remove-old-mail.py", pid=pid, action=loop, keep_fds=keep_fds)
daemon.start()
#run_once()



