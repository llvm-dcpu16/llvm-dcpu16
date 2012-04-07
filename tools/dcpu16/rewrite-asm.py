#!/usr/bin/python
# Copyright (c) 2012, BungaDunga from Reddit

# Usage: ./rewrite-asm.py inputFileName outputFileName

import sys
file = open(sys.argv[1])
out = open(sys.argv[2], "w")
result = """:autoinit
  SET C, SP
  SUB C, 256
:automain
  ;; Please put your startup code below
  ;; <here>
  SET PC, break
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

# Must be changed to print(result) for Python 3+
print result
out.write(result)
