#!/usr/bin/env python3

# For more info:
# https://www.mikekohn.net/

import sys, os
import msp430

def upload_program(index, msp430, filename):
  length = os.path.getsize(filename)

  print("Reading: " + filename + " length=" + str(length) + " bytes")
  count = 0

  print("%02x %02x" % (length & 0xff, length >> 8))

  # Send program command.
  msp430.send_byte(index, 0x01)

  # Send the length of the program.
  msp430.send_byte(index, length & 0xff)
  msp430.send_byte(index, length >> 8)

  fp = open(filename, "rb")

  while True:
    if (count % 100) == 0: print(" ... " + str(count))

    byte = fp.read(1)
    if not byte: break

    byte = int.from_bytes(byte, "little")
    msp430.send_byte(index, byte)

    count += 1

  fp.close()

# -------------------------------- fold here ----------------------------

if len(sys.argv) != 3:
  print("Usage: python3 cluster_upload.py <index> <filename>")
  sys.exit(0)

msp430.open()
upload_program(int(sys.argv[1]), msp430, sys.argv[2])
msp430.close()

