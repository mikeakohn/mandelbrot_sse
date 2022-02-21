#!/usr/bin/env python3

class bmp:
  def __init__(self, filename, width, height):
    self.fp = open("out.bmp", "wb+")
    self.width = width
    self.height = height
    self.image_length = self.width * self.height * 3
    self.header_length = 54
    self.length = self.header_length + self.image_length

  def write_header(self):
    self.fp.write(b"BM")
    self.fp.write(self.length.to_bytes(4, 'little'))
    self.fp.write((0).to_bytes(2, 'little'))
    self.fp.write((0).to_bytes(2, 'little'))
    self.fp.write((54).to_bytes(4, 'little'))

    self.fp.write((40).to_bytes(4, 'little'))
    self.fp.write(self.width.to_bytes(4, 'little'))
    self.fp.write(self.height.to_bytes(4, 'little'))
    self.fp.write((1).to_bytes(2, 'little'))
    self.fp.write((24).to_bytes(2, 'little'))
    self.fp.write((0).to_bytes(4, 'little'))
    self.fp.write(self.image_length.to_bytes(4, 'little'))
    self.fp.write((0).to_bytes(4, 'little'))
    self.fp.write((0).to_bytes(4, 'little'))
    self.fp.write((0).to_bytes(4, 'little'))
    self.fp.write((0).to_bytes(4, 'little'))

    self.clear()

  def clear(self):
    for i in range(0, 640 * 480):
      self.fp.write((0).to_bytes(3, 'little'))

  def plot(self, x, y, color):
    self.fp.seek(self.header_length + ((y * self.width * 3) + (x * 3)))
    self.fp.write(color.to_bytes(3, 'little'))

  def close(self):
    self.fp.close()

