import 'dart:typed_data';

import 'common.dart';
import 'internal.dart';
import 'positional_byte_reader.dart';

class WavDataReader
{
  PositionalByteReader byteReader;

  WavDataReader(this.byteReader);

  // Helper functions
  int readU8() => byteReader.read(1).getUint8(0);
  int readU16() => byteReader.read(2).getUint16(0, Endian.little);
  int readU24() => readU8() + 0x100 * readU16();
  int readU32() => byteReader.read(4).getUint32(0, Endian.little);

  // Sample readers for the various different file formats
  double readS8() => u2f(readU8(), 8);
  double readS16() => u2f(fold(readU16(), 16), 16);
  double readS24() => u2f(fold(readU24(), 24), 24);
  double readS32() => u2f(fold(readU32(), 32), 32);
  double readF32() => byteReader.read(4).getFloat32(0, Endian.little);
  double readF64() => byteReader.read(8).getFloat64(0, Endian.little);

  // Returns the appropriate sample reader for a particular format
  double Function() sampleReader(WavFormat format) => [
      readS8, readS16, readS24, readS32, readF32, readF64
      ][format.index];

  /// Read raw audio data from a byte buffer (assumes no header information
  /// is present in the buffer so needs that meta data to be known up front
  /// and supplied as a parameter)
  List<Float64List> readData(WavHeader header)
  {
    // Read samples.
    final readSample = sampleReader(header.format);
    final channels = <Float64List>[];
    for (int i = 0; i < header.numChannels; ++i) {
      channels.add(Float64List(header.numSamples));
    }
    for (int i = 0; i < header.numSamples; ++i) {
      for (int j = 0; j < header.numChannels; ++j) {
        channels[j][i] = readSample();
      }
    }
    return channels;
  }
}