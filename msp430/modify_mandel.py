#!/usr/bin/env python3

lines = [ ]

fp = open("mandelbrot.asm", "r")

copying = False

for line in fp:
  if line.startswith("calculate_II:"):
    copying = True

  if line.startswith("; _mul a * b"): break
  if line.startswith(".org 0xfffe"): break
  if not copying: continue

  lines.append(line)

fp.close()

fp = open("mandelbrot.asm", "w")

fp.write(".msp430\n\n")
fp.write(".org 0xfa00\n\n")

for line in lines:
  fp.write(line)

fp.close()

