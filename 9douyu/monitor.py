#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
monitor jdy online server if cup usage greater than 60% send dingding warning message
and send top10 ip address.
"""

import subprocess
import commands
import time

def run_cmd(cmd):
    return commands.getstatusoutput(cmd)

def call(cmd):
    args = ['/bin/bash', '-c', cmd]
    subprocess.call(args)

def send_message(message):
    cmd="""curl https://oapi.dingtalk.com/robot/send?access_token=e78992df5bd808942e30c340a8f83beed433c1aa619bcf6b83044dc341d122fc \
        -H 'Content-Type: application/json' \
        -d '
          {"msgtype": "text",
            "text": {
                "content": "%s"
             }
          }'""" % message
    call(cmd)

def monitor():
    print time.ctime()
    sar_cmd = "sar -u | tail -2"
    sar_result = run_cmd(sar_cmd)[1].split("\n")
    cpu_usage = sar_result[0].split()
    lines = 5

    if float(cpu_usage[3]) > 60.0:
        cpu_message = 'CPU Usage: %s%%; Last Time : %s' % (cpu_usage[3],cpu_usage[0])
        today = time.strftime("%Y%m%d", time.localtime())
        cmd="cat /opt/lampp/logs/*.9douyu.com.*.log.%s |awk '{print $1}' | sort | uniq -c | sort -nr | head -%d" % (today,lines)
	print cmd
        req_result = run_cmd(cmd)[1].split("\n")

        hostname = run_cmd('hostname')[1]
        message = "hostname : %s\n %s \n" % (hostname,cpu_message)
        for text in req_result[0:lines]:
            text = text.strip().split()
            message += "IP : " + text[1] + ' --- Num :' + text[0] + "\n"

        send_message(message)

if __name__ == "__main__":
    monitor()
