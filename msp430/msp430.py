#!/usr/bin/env python

import gpiozero
import spidev
import time

def open():
  nodes[0]["cs"].off();
  nodes[1]["cs"].off();
  nodes[2]["cs"].off();
  nodes[3]["cs"].off();

  # Pause for a second.
  print("Starting up...")

  # Initialize SPI bus.
  global spi

  spi = spidev.SpiDev()
  spi.open(0, 0)
  spi.mode = 0
  spi.bits_per_word = 8
  spi.lsbfirst = False
  spi.no_cs = True
  spi.max_speed_hz = 100000

  time.sleep(1)

def wait_busy(node):
  while not node["busy"].is_pressed: continue

def is_busy(index):
  node = nodes[index]
  return not node["busy"].is_pressed

def send_byte(index, data):
  node = nodes[index]

  node["cs"].on()

  wait_busy(node)
  values = spi.xfer2([ data ])

  node["cs"].off()

  return values[0]

def close():
  spi.close()

# ----------------------------- fold here -------------------------------

nodes = [
  { "cs": gpiozero.LED(17), "busy": gpiozero.Button(27) },
  { "cs": gpiozero.LED(5),  "busy": gpiozero.Button(6)  },
  { "cs": gpiozero.LED(13), "busy": gpiozero.Button(19) },
  { "cs": gpiozero.LED(16), "busy": gpiozero.Button(20) },
]

