import wave
import math as math

def toI16(x):
  return min(max(x * 32768, -32768), 32767)

def toU8(x):
  return (min(max(x * 128, -128), 127) + 128) % 256

def toI24(x):
  return min(max(x * (2 ** 23), -(2 ** 23)), 2 ** 23 - 1)

def toI32(x):
  return min(max(x * (2 ** 31), -(2 ** 31)), 2 ** 31 - 1)

def gen(bits):
  b = bits // 8
  f = [toU8, toI16, toI24, toI32][b - 1]
  s = b != 1
  a = []
  for i in range(101):
    t = i * 2 * math.pi * 400 / 8000
    a.append(math.sin(t))
    a.append(math.cos(t))
  with wave.open('400Hz-%dbit.wav' % bits, 'wb') as w:
    w.setnchannels(2)
    w.setsampwidth(b)
    w.setframerate(8000)
    w.writeframes(b"".join([
        int(f(i)).to_bytes(b, byteorder='little', signed=s) for i in a]))

gen(8)
gen(16)
gen(24)
gen(32)
