#!/bin/python2

import subprocess, uuid, os, ftplib

home = os.path.expanduser("~")
documents = os.path.join(home, "Documents")
uuid = str(uuid.uuid1())
archive="avast_gather_" + uuid + ".tar.bz2"

print("Packing {}/Documents/avast_gather directory into {}/{}".format(documents, documents, archive))
subprocess.call(["/usr/bin/tar", "-cjf", os.path.join(documents, archive), os.path.join(documents, "avast_gather")])

session = ftplib.FTP('ftp.avast.com')
session.login()
file = open(home + '/tmp/test.txt','rb')
session.storbinary('STOR incoming/test.txt', file)
file.close()
session.quit()


