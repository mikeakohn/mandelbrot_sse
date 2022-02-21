#!/usr/bin/env python3

def to_fixed(f):
  negative = False

  if f < 0:
    negative = True
    f = -f

  i = int(f)
  f = f - float(i)

  i = i << 12
  i += int(float(0x1000) * f) & 0xfff

  if negative: i = (i ^ 0xffff) + 1

  return i & 0xffff

def to_float(i):
  negative = False

  if (i & 0x8000):
    negative = True
    i = (i ^ 0xffff) + 1

  n = i & 0xfff
  i = i >> 12

  f = float(i) + (float(n) / 0x1000)

  if negative: f = -f

  return f

def square(a):
  total = 0

  if (a & 0x8000) != 0:
    a = (a ^ 0xffff) + 1

  b = a

  while b != 0:
    if (b & 1) != 0: total += a

    a = a << 1
    b = b >> 1

  return (total >> 12) & 0xffff

def mul32(a, b):
  total = 0
  count = 0

  if (a & 0x8000) != 0: a |= 0xffff0000
  if (b & 0x8000) != 0: b |= 0xffff0000

  while b != 0 and count < 32:
    if (b & 1) != 0: total += a

    a = a << 1
    b = b >> 1

    count += 1

  return (total >> 12) & 0xffff

def umul16(a, b):
  is_negative = 0
  total = 0

  if (a & 0x8000) != 0:
    a = (a ^ 0xffff) + 1
    is_negative += 1

  if (b & 0x8000) != 0:
    b = (b ^ 0xffff) + 1
    is_negative += 1

  while b != 0:
    if (b & 1) != 0: total += a

    a = a << 1
    b = b >> 1

  total = (total >> 12) & 0xffff

  if (is_negative & 1) == 1: total = (total ^ 0xffff) + 1

  return total

def calculate_fixed(r, i):
  zr = 0
  zi = 0

  for count in range(0, 128):
    zr2 = square(zr)
    zi2 = square(zi)

    if (((zr2 + zi2) & 0xffff) >> 12) > 4: break

    tr = (zr2 - zi2) & 0xffff
    ti = (umul16(zr, zi) << 1) & 0xffff
    zr = (tr + r) & 0xffff
    zi = (ti + i) & 0xffff

  return count

def calculate_float(r, i):
  zr = 0
  zi = 0

  for count in range(0, 128):
    tr = ((zr * zr) - (zi * zi))
    ti = 2 * zr * zi
    zr = tr + r
    zi = ti + i
    if (zr * zr) + (zi * zi) > 4: break

  return count

