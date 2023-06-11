
import 'dart:typed_data';

import 'wav_format.dart';

/// Reads a series of bytes, keeping track of the position (i.e. number of bytes
/// already read) in the bytes stream.
class PositionalByteReader
{
  final Uint8List bytes;
  int p;

  PositionalByteReader(this.bytes, { this.p = 0, });
    
  void skip(int n) {
    p += n;
    if (p > bytes.length) {
      throw FormatException('WAV is corrupted, or not a WAV file.');
    }
  }

  ByteData read(int n) {
    final p0 = p;
    skip(n);
    return ByteData.sublistView(bytes, p0, p);
  }

  // [0, 2] => [0, 2 ^ bits - 1]
  static double _wScale(int bits) => (1 << (bits - 1)) * 1.0;
  static double _rScale(int bits) => _wScale(bits) - 0.5;
  static int _fold(int x, int bits) => (x + (1 << (bits - 1))) % (1 << bits);
  static double u2f(int x, int b) => (x / _rScale(b)) - 1;

  int readU8() => read(1).getUint8(0);
  int readU16() => read(2).getUint16(0, Endian.little);
  int readU24() => readU8() + 0x100 * readU16();
  int readU32() => read(4).getUint32(0, Endian.little);
  double readS8() => u2f(readU8(), 8);
  double readS16() => u2f(_fold(readU16(), 16), 16);
  double readS24() => u2f(_fold(readU24(), 24), 24);
  double readS32() => u2f(_fold(readU32(), 32), 32);
  double readF32() => read(4).getFloat32(0, Endian.little);
  double readF64() => read(8).getFloat64(0, Endian.little);

  double Function() sampleReader(WavFormat format) => [
      readS8, readS16, readS24, readS32, readF32, readF64
      ][format.index];

}