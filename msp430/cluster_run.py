#!/usr/bin/env python3

import sys
import bmp
import software
import msp430

colors = [
  0xff0000,  # f
  0xee3300,  # e
  0xcc5500,  # d
  0xaa5500,  # c
  0xaa3300,  # b
  0x666600,  # a
  0x999900,  # 9
  0x669900,  # 8
  0x339900,  # 7
  0x0099aa,  # 6
  0x0066aa,  # 5
  0x0033aa,  # 4
  0x0000aa,  # 3
  0x000099,  # 2
  0x000066,  # 1
  0x000000,  # 0
]

def calculate_start(index, r, i):
  msp430.send_byte(index, 3)
  msp430.send_byte(index, r & 0xff)
  msp430.send_byte(index, r >> 8)
  msp430.send_byte(index, 4)
  msp430.send_byte(index, i & 0xff)
  msp430.send_byte(index, i >> 8)

  msp430.send_byte(index, 2)

def get_result(index):
  count = msp430.send_byte(index, 0)

  return count

# ----------------------------- fold here ------------------------------

width = 640
height = 480

bmp = bmp.bmp("out.bmp", width, height)
bmp.write_header()

#r0 = -2.00
#r1 =  1.00
#i0 = -1.00
#i1 =  1.00
r0 = 0.37 - 0.00
r1 = 0.37 + 0.04
i0 = -0.2166 - 0.02
i1 = -0.2166 + 0.02

r_step = (r1 - r0) / width;
i_step = (i1 - i0) / height;

r = r0
i = i0

msp430.open()

POS_X = 0
POS_Y = 1
RUNNING = 2
COUNT = 3

nodes = [
  [ 0, 0, False, 0 ],
  [ 0, 0, False, 0 ],
  [ 0, 0, False, 0 ],
  [ 0, 0, False, 0 ]
]

y = 0
x = 0

max_index = 4
running = True

index = 0
while running:
  node = nodes[index]

  #print("index: " + str(index) + " " + str(node))

  if node[RUNNING]:
    if not msp430.is_busy(index):
      count = get_result(index)
      bmp.plot(node[POS_X], node[POS_Y], colors[count >> 3])
      node[RUNNING] = False

  if not node[RUNNING]:
    if y < height:
      calculate_start(index, software.to_fixed(r), software.to_fixed(i))

      #print("start: " + str(index) + " " + str(msp430.is_busy(index)))

      node[RUNNING] = True
      node[POS_X] = x
      node[POS_Y] = y
      node[COUNT] += 1

      x += 1
      r += r_step

      if x == width:
        x = 0
        r = r0
        y += 1
        i += i_step
        print(y)
        #if y == 480:
        #  for i in range(0, 4):
        #    print(str(i) + ": " + str(nodes[i][COUNT]))
    else:
      running = False

      for i in range(0, max_index):
        if nodes[i][RUNNING] == True: running = True 

      print(running)
      print(nodes)

  index += 1
  if index == max_index: index = 0

for i in range(0, 4):
  print(str(i) + ": " + str(nodes[i][COUNT]))

msp430.close()
bmp.close()

