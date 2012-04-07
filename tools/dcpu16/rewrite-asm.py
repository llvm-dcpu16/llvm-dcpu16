#!/usr/bin/python
# Copyright (c) 2012, BungaDunga from Reddit

import sys
file = open(sys.argv[1])

import sys
file = open(sys.argv[1])
out = open(sys.argv[2], "w")
result = """:init
  SET C, SP
  SUB C, 256
"""

for line in file.readlines():
    try:
        for symbol in ["file", "text", "globl", "align", "type", "size"]:
            if line.strip().find("."+symbol) == 0:
                raise Error
            except:
                continue
            if len(line.split()) and line.strip()[0] != ";":
                if line.split()[0][-1] == ":":
                    line =  " ".join([":"+line.split(" ")[0][:-1]]  + line.split(" ")[1:])
                    result = result + line
                    
result = result + """
:break
  BRK

:crash
  SET PC, crash
"""
print result
out.write(result)
